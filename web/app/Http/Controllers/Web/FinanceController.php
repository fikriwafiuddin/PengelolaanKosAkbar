<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseRequest;
use App\Models\Expense;
use App\Services\FinanceService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;
use Inertia\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Laporan Keuangan di dashboard admin: rekap kas pemasukan sewa,
 * pengeluaran operasional, laba bulanan, laporan pembayaran, dan
 * ekspor CSV (Sprint 4). Controller tipis — logika di FinanceService.
 */
class FinanceController extends Controller
{
    public function __construct(private readonly FinanceService $finance)
    {}

    /**
     * GET /finance?month=YYYY-MM — halaman Laporan Keuangan.
     */
    public function index(Request $request): Response
    {
        $month = $this->resolveMonth($request->query('month'));

        return Inertia::render('finance/index', [
            'month' => $month,
            'summary' => $this->finance->summary($month),
            'months' => $this->finance->availableMonths(),
            'trend' => $this->finance->trend($month),
            'paymentReport' => $this->finance->paymentReport($month),
            'expenseByCategory' => $this->finance->expenseByCategory($month),
            'expenses' => $this->expensesWithLabels($month),
        ]);
    }

    /**
     * POST /finance/expenses — catat pengeluaran operasional.
     */
    public function storeExpense(StoreExpenseRequest $request): RedirectResponse
    {
        $this->finance->createExpense($request->user(), $request->validated());

        return back()->with('success', 'Pengeluaran berhasil dicatat.');
    }

    /**
     * DELETE /finance/expenses/{expense} — hapus catatan pengeluaran.
     */
    public function destroyExpense(Request $request, Expense $expense): RedirectResponse
    {
        $this->finance->deleteExpense($expense);

        return back()->with('success', 'Catatan pengeluaran dihapus.');
    }

    /**
     * GET /finance/export?type=pembayaran|kas&month=YYYY-MM — unduh
     * laporan sebagai berkas CSV (dibuka Excel/Sheets).
     */
    public function export(Request $request): StreamedResponse
    {
        $month = $this->resolveMonth($request->query('month'));
        $type = $request->query('type') === 'kas' ? 'kas' : 'pembayaran';

        $rows = $type === 'kas'
            ? $this->finance->cashReportRows($month)
            : $this->finance->paymentReportRows($month);

        $filename = "laporan-{$type}-kost-akbar-{$month}.csv";

        return response()->streamDownload(function () use ($rows) {
            $handle = fopen('php://output', 'w');

            // BOM UTF-8 agar Excel membaca teks Indonesia dengan benar.
            fwrite($handle, "\xEF\xBB\xBF");

            foreach ($rows as $row) {
                fputcsv($handle, $row, ';', enclosure: '"');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    /**
     * Validasi parameter month (fallback: bulan berjalan).
     */
    private function resolveMonth(mixed $month): string
    {
        return is_string($month) && preg_match('/^\d{4}-\d{2}$/', $month)
            ? $month
            : now()->format('Y-m');
    }

    /**
     * Daftar pengeluaran + label tanggal siap tampil.
     *
     * @return array<int, array<string, mixed>>
     */
    private function expensesWithLabels(string $month): array
    {
        return $this->finance->expenses($month)
            ->map(fn (Expense $expense) => [
                'id' => $expense->id,
                'expense_date' => $expense->expense_date->toDateString(),
                'expense_date_formatted' => $expense->expense_date->locale('id')->translatedFormat('d M Y'),
                'category' => $expense->category,
                'description' => $expense->description,
                'amount' => (float) $expense->amount,
                'amount_formatted' => 'Rp '.number_format((float) $expense->amount, 0, ',', '.'),
                'creator_name' => $expense->creator?->name,
            ])
            ->all();
    }
}

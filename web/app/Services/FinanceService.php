<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Logika bisnis laporan keuangan (Sprint 4): rekap kas pemasukan
 * sewa, rekap pengeluaran operasional, laba bulanan, laporan
 * pembayaran per penghuni, dan ekspor CSV.
 */
class FinanceService
{
    /**
     * Ringkasan satu bulan: pemasukan (pembayaran terverifikasi),
     * pengeluaran, dan laba — ditambah pembanding bulan sebelumnya.
     *
     * @return array<string, mixed>
     */
    public function summary(string $month): array
    {
        $previous = Carbon::parse($month.'-01')->subMonth()->format('Y-m');

        $income = $this->incomeTotal($month);
        $previousIncome = $this->incomeTotal($previous);
        $expense = $this->expenseTotal($month);
        $previousExpense = $this->expenseTotal($previous);

        return [
            'month' => $month,
            'month_label' => Carbon::parse($month.'-01')->locale('id')->translatedFormat('F Y'),
            'income' => $income,
            'previous_income' => $previousIncome,
            'income_change' => $previousIncome > 0
                ? round((($income - $previousIncome) / $previousIncome) * 100, 1)
                : null,
            'expense' => $expense,
            'previous_expense' => $previousExpense,
            'profit' => $income - $expense,
            'previous_profit' => $previousIncome - $previousExpense,
        ];
    }

    /**
     * Total kas pemasukan bulan ini: pembayaran terverifikasi pada
     * periode tagihan bulan tsb.
     */
    public function incomeTotal(string $month): float
    {
        return (float) Payment::query()
            ->where('status', 'terverifikasi')
            ->whereHas('invoice', fn (Builder $query) => $query->where('period', $month))
            ->sum('amount');
    }

    /**
     * Total pengeluaran operasional satu bulan.
     */
    public function expenseTotal(string $month): float
    {
        return (float) Expense::query()
            ->whereBetween('expense_date', [
                Carbon::parse($month.'-01')->startOfMonth()->toDateString(),
                Carbon::parse($month.'-01')->endOfMonth()->toDateString(),
            ])
            ->sum('amount');
    }

    /**
     * Rekap pengeluaran satu bulan per kategori (untuk grafik /
     * rincian).
     *
     * @return Collection<int, array<string, mixed>>
     */
    public function expenseByCategory(string $month): Collection
    {
        return Expense::query()
            ->whereBetween('expense_date', [
                Carbon::parse($month.'-01')->startOfMonth()->toDateString(),
                Carbon::parse($month.'-01')->endOfMonth()->toDateString(),
            ])
            ->selectRaw('category, COUNT(*) AS total_items, SUM(amount) AS total_amount')
            ->groupBy('category')
            ->orderByDesc('total_amount')
            ->get()
            ->map(fn ($row) => [
                'category' => $row->category,
                'total_items' => (int) $row->total_items,
                'total_amount' => (float) $row->total_amount,
            ]);
    }

    /**
     * Daftar pengeluaran satu bulan (terbaru duluan).
     */
    public function expenses(string $month): Collection
    {
        return Expense::query()
            ->whereBetween('expense_date', [
                Carbon::parse($month.'-01')->startOfMonth()->toDateString(),
                Carbon::parse($month.'-01')->endOfMonth()->toDateString(),
            ])
            ->with('creator:id,name')
            ->orderByDesc('expense_date')
            ->orderByDesc('id')
            ->get();
    }

    /**
     * Tambah catatan pengeluaran operasional.
     */
    public function createExpense(User $admin, array $data): Expense
    {
        return Expense::query()->create([
            ...$data,
            'created_by' => $admin->id,
        ]);
    }

    /**
     * Hapus catatan pengeluaran.
     */
    public function deleteExpense(Expense $expense): void
    {
        $expense->delete();
    }

    /**
     * Laporan pembayaran sewa per penghuni untuk satu periode tagihan:
     * lunas / belum, nominal dibayar, kamar.
     *
     * @return Collection<int, array<string, mixed>>
     */
    public function paymentReport(string $month): Collection
    {
        return Payment::query()
            ->where('status', 'terverifikasi')
            ->whereHas('invoice', fn (Builder $query) => $query->where('period', $month))
            ->with(['invoice.booking.room:id,room_number', 'invoice.booking.resident.user:id,name', 'verifier:id,name'])
            ->orderByDesc('paid_at')
            ->get()
            ->map(fn (Payment $payment) => [
                'id' => $payment->id,
                'resident_name' => $payment->invoice->booking->resident->user->name
                    ?? $payment->invoice->booking->resident->full_name,
                'room_number' => $payment->invoice->booking->room?->room_number,
                'period' => $payment->invoice->period,
                'amount' => (float) $payment->amount,
                'method' => $payment->method,
                'method_label' => $payment->methodLabel(),
                'receipt_no' => $payment->receipt_no,
                'paid_at_formatted' => $payment->paid_at?->locale('id')->translatedFormat('d F Y'),
            ]);
    }

    /**
     * Tren 6 bulan terakhir (sampai bulan aktif) untuk grafik mini:
     * pemasukan, pengeluaran, laba.
     *
     * @return Collection<int, array<string, mixed>>
     */
    public function trend(string $month): Collection
    {
        $start = Carbon::parse($month.'-01')->subMonths(5);

        return collect(range(0, 5))
            ->map(fn (int $offset) => $start->copy()->addMonths($offset)->format('Y-m'))
            ->map(fn (string $period) => [
                'month' => $period,
                'month_label' => Carbon::parse($period.'-01')->locale('id')->translatedFormat('M y'),
                'income' => $this->incomeTotal($period),
                'expense' => $this->expenseTotal($period),
                'profit' => $this->incomeTotal($period) - $this->expenseTotal($period),
            ]);
    }

    /**
     * Daftar bulan yang memiliki transaksi (untuk pilihan periode).
     *
     * @return Collection<int, array{value: string, label: string}>
     */
    public function availableMonths(): Collection
    {
        $paymentMonths = Payment::query()
            ->where('payments.status', 'terverifikasi')
            ->join('invoices', 'invoices.id', '=', 'payments.invoice_id')
            ->pluck('invoices.period');

        $expenseMonths = Expense::query()
            ->pluck('expense_date')
            ->map(fn ($date) => Carbon::parse($date)->format('Y-m'));

        return $paymentMonths
            ->merge($expenseMonths)
            ->unique()
            ->sortDesc()
            ->values()
            ->map(fn (string $period) => [
                'value' => $period,
                'label' => Carbon::parse($period.'-01')->locale('id')->translatedFormat('F Y'),
            ]);
    }

    /**
     * Baris CSV laporan pembayaran satu bulan.
     *
     * @return array<int, array<int, string>>
     */
    public function paymentReportRows(string $month): array
    {
        $rows = [[
            'No', 'Penghuni', 'Kamar', 'Periode', 'Nominal', 'Metode', 'No. Kuitansi', 'Tanggal Bayar',
        ]];

        foreach ($this->paymentReport($month)->values() as $index => $payment) {
            $rows[] = [
                (string) ($index + 1),
                $payment['resident_name'],
                'Kamar '.($payment['room_number'] ?? '-'),
                $payment['period'],
                'Rp '.number_format($payment['amount'], 0, ',', '.'),
                $payment['method_label'],
                $payment['receipt_no'] ?? '-',
                $payment['paid_at_formatted'] ?? '-',
            ];
        }

        return $rows;
    }

    /**
     * Baris CSV rekap kas (pemasukan + pengeluaran + laba) satu bulan.
     *
     * @return array<int, array<int, string>>
     */
    public function cashReportRows(string $month): array
    {
        $summary = $this->summary($month);

        $rows = [
            ['Laporan Kas Kost Akbar — '.$summary['month_label']],
            [],
            ['Jenis', 'Kategori', 'Keterangan', 'Nominal'],
            ['Pemasukan', 'Sewa Kamar', 'Pembayaran terverifikasi periode '.$month, 'Rp '.number_format($summary['income'], 0, ',', '.')],
        ];

        foreach ($this->expenses($month) as $expense) {
            $rows[] = [
                'Pengeluaran',
                $expense->category,
                $expense->description ?? '-',
                'Rp '.number_format((float) $expense->amount, 0, ',', '.'),
            ];
        }

        $rows[] = [];
        $rows[] = ['LABA BULAN INI', '', '', 'Rp '.number_format($summary['profit'], 0, ',', '.')];

        return $rows;
    }
}

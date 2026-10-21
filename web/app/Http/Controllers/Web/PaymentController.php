<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\PaymentVerificationRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Payment;
use App\Services\PaymentService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Verifikasi pembayaran sewa + cetak kuitansi di dashboard admin.
 * Controller tipis — logika ada di PaymentService.
 */
class PaymentController extends Controller
{
    public function __construct(private readonly PaymentService $payments)
    {}

    /**
     * GET /payments — halaman Verifikasi Pembayaran + riwayat transaksi
     * (filter status, periode tagihan, dan pencarian).
     */
    public function index(Request $request): Response
    {
        $filters = $request->only(['status', 'q', 'month']);
        $payments = $this->payments->list($filters);

        return Inertia::render('payments/index', [
            'payments' => [
                'data' => PaymentResource::collection($payments->items())->resolve(),
                'current_page' => $payments->currentPage(),
                'last_page' => $payments->lastPage(),
                'total' => $payments->total(),
            ],
            'filters' => $filters,
            'statusCounts' => $this->payments->statusCounts(),
            'verifiedTotal' => $this->payments->verifiedTotal($filters),
        ]);
    }

    /**
     * PUT /payments/{payment}/verification — setujui / tolak pembayaran.
     */
    public function update(PaymentVerificationRequest $request, Payment $payment): RedirectResponse
    {
        $this->payments->verify($payment, $request->user(), $request->validated('status'));

        $message = $request->validated('status') === 'terverifikasi'
            ? 'Pembayaran berhasil diverifikasi dan kuitansi diterbitkan.'
            : 'Pembayaran ditolak. Tagihan kembali berstatus belum bayar.';

        return back()->with('success', $message);
    }

    /**
     * GET /payments/{payment}/receipt — kuitansi pembayaran (siap cetak).
     */
    public function receipt(Payment $payment): Response
    {
        return Inertia::render('payments/receipt', [
            'payment' => (new PaymentResource($this->payments->find($payment)))->resolve(),
            'printedAt' => now()->locale('id')->translatedFormat('d F Y, H:i'),
        ]);
    }
}

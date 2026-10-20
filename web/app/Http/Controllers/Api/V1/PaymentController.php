<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\SubmitPaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Invoice;
use App\Services\InvoiceService;
use App\Services\PaymentService;
use Illuminate\Http\JsonResponse;

/**
 * Pengiriman pembayaran sewa dari aplikasi mobile: input nominal +
 * unggah bukti bayar, diverifikasi admin setelahnya.
 */
class PaymentController extends Controller
{
    public function __construct(
        private readonly PaymentService $payments,
        private readonly InvoiceService $invoices,
    ) {}

    /**
     * POST /api/v1/invoices/{invoice}/payments — kirim pembayaran
     * untuk satu tagihan milik penghuni login.
     */
    public function store(SubmitPaymentRequest $request, Invoice $invoice): JsonResponse
    {
        // Pastikan tagihan benar milik penghuni yang login (404 bila bukan).
        $invoice = $this->invoices->findForUser($request->user(), $invoice);

        $payment = $this->payments->submit(
            $request->user(),
            $invoice,
            $request->validated(),
            $request->file('proof'),
        );

        return (new PaymentResource($payment->load('invoice')))
            ->response()
            ->setStatusCode(201);
    }
}

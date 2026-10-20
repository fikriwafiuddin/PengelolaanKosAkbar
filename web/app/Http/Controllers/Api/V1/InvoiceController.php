<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\InvoiceResource;
use App\Models\Invoice;
use App\Services\InvoiceService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Tagihan sewa bulanan milik penghuni (aplikasi mobile).
 * Controller tipis — logika ada di InvoiceService.
 */
class InvoiceController extends Controller
{
    public function __construct(private readonly InvoiceService $invoices)
    {}

    /**
     * GET /api/v1/invoices — rincian + ringkasan total tagihan.
     */
    public function index(): AnonymousResourceCollection
    {
        ['invoices' => $invoices, 'summary' => $summary] = $this->invoices->listForUser(request()->user());

        return InvoiceResource::collection($invoices)->additional([
            'summary' => $summary,
        ]);
    }

    /**
     * GET /api/v1/invoices/{invoice} — detail satu tagihan + riwayat
     * pembayarannya (404 bila bukan milik penghuni login).
     */
    public function show(Request $request, Invoice $invoice): InvoiceResource
    {
        return new InvoiceResource(
            $this->invoices->findForUser($request->user(), $invoice),
        );
    }
}

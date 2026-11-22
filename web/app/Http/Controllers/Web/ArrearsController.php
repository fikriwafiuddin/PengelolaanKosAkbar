<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Services\ArrearsService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Controller menu baru: Data Tunggakan Pembayaran Sewa.
 * Memudahkan admin mencari anak/penghuni yang belum bayar atau telat bayar,
 * serta melihat total uang menunggak.
 */
class ArrearsController extends Controller
{
    public function __construct(private readonly ArrearsService $arrears)
    {}

    /**
     * GET /arrears — halaman Data Tunggakan Penghuni.
     */
    public function index(Request $request): Response
    {
        $filters = $request->only(['q', 'overdue_only', 'period']);
        $invoices = $this->arrears->list($filters);

        $mappedItems = collect($invoices->items())->map(function (Invoice $inv) {
            $booking = $inv->booking;
            $resident = $booking?->resident;
            $user = $resident?->user;
            $room = $booking?->room;

            return [
                'id' => $inv->id,
                'period' => $inv->period,
                'period_label' => $inv->periodLabel(),
                'amount' => (float) $inv->amount,
                'amount_formatted' => 'Rp '.number_format((float) $inv->amount, 0, ',', '.'),
                'due_date' => $inv->due_date?->toDateString(),
                'due_date_formatted' => $inv->due_date?->locale('id')->translatedFormat('d M Y'),
                'is_overdue' => $inv->isOverdue(),
                'resident_id' => $resident?->id,
                'resident_name' => $resident?->full_name ?? $user?->name ?? '-',
                'phone' => $user?->phone,
                'room_number' => $room?->room_number ?? '-',
                'room_type' => $room?->type ?? '-',
                'booking_duration_months' => $booking?->duration_months,
            ];
        });

        return Inertia::render('arrears/index', [
            'invoices' => [
                'data' => $mappedItems,
                'current_page' => $invoices->currentPage(),
                'last_page' => $invoices->lastPage(),
                'total' => $invoices->total(),
            ],
            'filters' => $filters,
            'summary' => $this->arrears->summary($filters),
        ]);
    }
}


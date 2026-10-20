<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreBookingRequest;
use App\Http\Resources\BookingResource;
use App\Services\BookingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Pemesanan kamar dari aplikasi mobile. Controller tipis —
 * logika ada di BookingService.
 */
class BookingController extends Controller
{
    public function __construct(private readonly BookingService $bookings)
    {}

    /**
     * GET /api/v1/bookings — riwayat pemesanan milik penghuni login.
     */
    public function index(): AnonymousResourceCollection
    {
        return BookingResource::collection(
            $this->bookings->listForUser(request()->user()),
        );
    }

    /**
     * POST /api/v1/bookings — pesan kamar (tanggal mulai + durasi),
     * tagihan bulanan dibuat otomatis.
     */
    public function store(StoreBookingRequest $request): JsonResponse
    {
        $booking = $this->bookings->create($request->user(), $request->validated());

        return (new BookingResource($booking))
            ->response()
            ->setStatusCode(201);
    }
}

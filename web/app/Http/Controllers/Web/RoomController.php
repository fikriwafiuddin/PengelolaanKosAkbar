<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRoomRequest;
use App\Http\Resources\RoomResource;
use App\Models\Facility;
use App\Models\Room;
use App\Services\RoomService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * CRUD data kamar (termasuk foto kamar) + cetak katalog di dashboard
 * admin. Controller tipis — logika ada di RoomService.
 */
class RoomController extends Controller
{
    public function __construct(private readonly RoomService $rooms)
    {}

    /**
     * GET /rooms — halaman Data Kamar (tabel + filter + urut).
     */
    public function index(Request $request): Response
    {
        $filters = $request->only(['q', 'type', 'status', 'sort']);

        return Inertia::render('rooms/index', [
            'rooms' => $this->rooms->list($filters, perPage: 15),
            'filters' => $filters,
            'facilities' => Facility::query()->orderBy('name')->get(['id', 'name']),
            'types' => $this->rooms->availableTypes(),
            'stats' => $this->rooms->stats(),
        ]);
    }

    /**
     * POST /rooms — simpan kamar baru (beserta foto bila diunggah).
     */
    public function store(StoreRoomRequest $request): RedirectResponse
    {
        $this->rooms->create(
            $request->only(['room_number', 'type', 'price_monthly', 'status', 'description']),
            $request->validated('facility_ids', []),
            $request->file('image'),
        );

        return back()->with('success', 'Kamar '.$request->validated('room_number').' berhasil ditambahkan.');
    }

    /**
     * PUT /rooms/{room} — perbarui data kamar (termasuk ganti/hapus foto).
     */
    public function update(StoreRoomRequest $request, Room $room): RedirectResponse
    {
        $this->rooms->update(
            $room,
            $request->only(['room_number', 'type', 'price_monthly', 'status', 'description']),
            $request->validated('facility_ids', []),
            $request->file('image'),
            $request->boolean('remove_image'),
        );

        return back()->with('success', 'Kamar '.$request->validated('room_number').' berhasil diperbarui.');
    }

    /**
     * DELETE /rooms/{room} — hapus kamar.
     */
    public function destroy(Room $room): RedirectResponse
    {
        $number = $room->room_number;

        $this->rooms->delete($room);

        return back()->with('success', "Kamar {$number} berhasil dihapus.");
    }

    /**
     * GET /rooms/print — halaman cetak katalog kamar (daftar referensi
     * fasilitas & harga untuk calon penghuni).
     */
    public function print(): Response
    {
        return Inertia::render('rooms/print', [
            'rooms' => RoomResource::collection($this->rooms->catalog())->resolve(),
            'printed_at' => now()->translatedFormat('d F Y'),
        ]);
    }
}

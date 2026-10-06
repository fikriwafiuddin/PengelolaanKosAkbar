<?php

namespace App\Services;

use App\Models\Resident;
use App\Models\Room;
use Illuminate\Support\Collection;

/**
 * Logika penyusun data ringkasan dashboard admin.
 */
class DashboardService
{
    public function __construct(
        private readonly RoomService $rooms,
        private readonly ResidentService $residents,
    ) {}

    /**
     * Seluruh angka ringkas yang ditampilkan di dashboard admin.
     */
    public function overview(): array
    {
        $roomStats = $this->rooms->stats();
        $residentStats = $this->residents->stats();

        return [
            'rooms' => $roomStats,
            'occupancy' => $this->occupancy($roomStats['total'], $roomStats['terisi']),
            'residents' => $residentStats,
            'vacant_rooms' => $this->vacantRooms(),
            'latest_residents' => $this->latestResidents(),
        ];
    }

    /**
     * Persentase okupansi kamar.
     */
    private function occupancy(int $total, int $terisi): float
    {
        if ($total === 0) {
            return 0.0;
        }

        return round($terisi / $total * 100, 1);
    }

    /**
     * Daftar kamar kosong (untuk panel "kamar siap huni").
     */
    private function vacantRooms(): Collection
    {
        return Room::query()
            ->where('status', 'kosong')
            ->orderBy('room_number')
            ->limit(6)
            ->get(['id', 'room_number', 'type', 'price_monthly']);
    }

    /**
     * Penghuni terbaru yang mulai menyewa (untuk panel aktivitas).
     */
    private function latestResidents(): Collection
    {
        return Resident::query()
            ->whereHas('activeBooking')
            ->with(['activeBooking.room'])
            ->latest('created_at')
            ->limit(6)
            ->get(['id', 'full_name', 'created_at'])
            ->map(fn (Resident $resident) => [
                'name' => $resident->full_name,
                'room' => $resident->activeBooking?->room?->room_number,
                'start_date' => $resident->activeBooking?->start_date?->format('d M Y'),
            ]);
    }
}

<?php

namespace App\Services;

use App\Models\Room;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * Logika bisnis pengelolaan data kamar: katalog, pencarian,
 * CRUD, dan statistik ketersediaan.
 */
class RoomService
{
    /**
     * Tipe kamar standar Kost Akbar (acuan filter katalog).
     */
    public const DEFAULT_TYPES = [
        'Lantai 1 - AC',
        'Lantai 2 - Reguler',
        'Lantai 3 - Reguler',
    ];

    /**
     * Daftar kamar dengan pencarian & filter (dipakai web admin dan API mobile).
     *
     * Filter yang didukung:
     * - q      : kata kunci (nomor kamar, tipe, deskripsi, nama fasilitas)
     * - type   : tipe kamar persis
     * - status : kosong|terisi|terbooking
     * - max_price : harga maksimal per bulan
     */
    public function list(array $filters = [], int $perPage = 12): LengthAwarePaginator
    {
        return Room::query()
            ->with('facilities')
            ->when($filters['q'] ?? null, fn (Builder $query, string $q) => $query->where(function (Builder $inner) use ($q) {
                $inner->where('room_number', 'like', "%{$q}%")
                    ->orWhere('type', 'like', "%{$q}%")
                    ->orWhere('description', 'like', "%{$q}%")
                    ->orWhereHas('facilities', fn (Builder $f) => $f->where('name', 'like', "%{$q}%"));
            }))
            ->when($filters['type'] ?? null, fn (Builder $query, string $type) => $query->where('type', $type))
            ->when($filters['status'] ?? null, fn (Builder $query, string $status) => $query->where('status', $status))
            ->when($filters['max_price'] ?? null, fn (Builder $query, $maxPrice) => $query->where('price_monthly', '<=', $maxPrice))
            ->orderBy('room_number')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Ambil satu kamar beserta fasilitasnya.
     */
    public function find(Room $room): Room
    {
        return $room->load('facilities');
    }

    /**
     * Tambah kamar baru beserta fasilitasnya.
     */
    public function create(array $data, array $facilityIds = []): Room
    {
        $room = Room::create($data);
        $room->facilities()->sync(array_unique($facilityIds));

        return $room->load('facilities');
    }

    /**
     * Perbarui data kamar dan fasilitasnya.
     */
    public function update(Room $room, array $data, array $facilityIds = []): Room
    {
        $room->update($data);
        $room->facilities()->sync(array_unique($facilityIds));

        return $room->load('facilities');
    }

    /**
     * Hapus kamar. Ditolak jika masih ada penyewa aktif / menunggu
     * konfirmasi agar riwayat transaksi tetap utuh.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function delete(Room $room): void
    {
        $hasActiveBooking = $room->bookings()
            ->whereIn('status', ['menunggu', 'aktif'])
            ->exists();

        if ($hasActiveBooking) {
            throw \Illuminate\Support\Facades\Validator::make([], [])->withErrors([
                'room' => 'Kamar tidak dapat dihapus karena masih memiliki penyewa aktif. Selesaikan atau batalkan pemesanan terlebih dahulu.',
            ]);
        }

        $room->facilities()->detach();
        $room->delete();
    }

    /**
     * Statistik ketersediaan kamar untuk kartu ringkasan & dashboard.
     */
    public function stats(): array
    {
        $rooms = Room::query()->select('status', 'type')->get();

        return [
            'total' => $rooms->count(),
            'terisi' => $rooms->where('status', 'terisi')->count(),
            'kosong' => $rooms->where('status', 'kosong')->count(),
            'terbooking' => $rooms->where('status', 'terbooking')->count(),
            'by_type' => $rooms->groupBy('type')
                ->map(fn (Collection $rooms, string $type) => [
                    'type' => $type,
                    'total' => $rooms->count(),
                    'kosong' => $rooms->where('status', 'kosong')->count(),
                ])
                ->values()
                ->all(),
        ];
    }

    /**
     * Daftar tipe kamar yang bisa dipilih pada form (default + yang
     * sudah terpakai di database).
     */
    public function availableTypes(): array
    {
        $used = Room::query()->distinct()->pluck('type')->all();

        return array_values(array_unique(array_merge(self::DEFAULT_TYPES, $used)));
    }
}

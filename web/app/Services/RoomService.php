<?php

namespace App\Services;

use App\Models\Room;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;

/**
 * Logika bisnis pengelolaan data kamar: katalog, pencarian,
 * CRUD, foto kamar, dan statistik ketersediaan.
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
     * - sort   : asc (default) | desc — urut nomor kamar secara numerik
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
            ->orderByRaw($this->roomOrderExpression($filters['sort'] ?? 'asc'))
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Katalog lengkap untuk halaman cetak: urut tipe lalu nomor kamar
     * secara numerik.
     *
     * @return Collection<int, Room>
     */
    public function catalog(): Collection
    {
        return Room::query()
            ->with('facilities')
            ->orderBy('type')
            ->orderByRaw($this->roomOrderExpression('asc'))
            ->get();
    }

    /**
     * Ekspresi ORDER BY nomor kamar secara numerik (1, 2, ..., 10, 29 —
     * bukan urutan teks 1, 10, 11, 2, ...). Arah di-whitelist demi
     * keamanan karena dirangkai ke orderByRaw.
     */
    private function roomOrderExpression(string $direction): string
    {
        $safeDirection = strtolower($direction) === 'desc' ? 'DESC' : 'ASC';

        return "CAST(room_number AS SIGNED) {$safeDirection}";
    }

    /**
     * Ambil satu kamar beserta fasilitasnya.
     */
    public function find(Room $room): Room
    {
        return $room->load('facilities');
    }

    /**
     * Tambah kamar baru beserta fasilitas dan fotonya.
     */
    public function create(array $data, array $facilityIds = [], ?UploadedFile $image = null): Room
    {
        if ($image) {
            $data['image_path'] = $image->store('rooms', 'public');
        }

        $room = Room::create($data);
        $room->facilities()->sync(array_unique($facilityIds));

        return $room->load('facilities');
    }

    /**
     * Perbarui data kamar, fasilitas, dan fotonya.
     *
     * Foto lama otomatis dihapus saat diganti / saat remove_image aktif.
     */
    public function update(
        Room $room,
        array $data,
        array $facilityIds = [],
        ?UploadedFile $image = null,
        bool $removeImage = false,
    ): Room {
        if ($image) {
            $this->deleteImageFile($room);
            $data['image_path'] = $image->store('rooms', 'public');
        } elseif ($removeImage) {
            $this->deleteImageFile($room);
            $data['image_path'] = null;
        }

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
            throw \Illuminate\Validation\ValidationException::withMessages([
                'room' => 'Kamar tidak dapat dihapus karena masih memiliki penyewa aktif. Selesaikan atau batalkan pemesanan terlebih dahulu.',
            ]);
        }

        $this->deleteImageFile($room);
        $room->facilities()->detach();
        $room->delete();
    }

    /**
     * Hapus berkas foto kamar dari disk public (aman dipanggil walau
     * kamar belum berfoto).
     */
    private function deleteImageFile(Room $room): void
    {
        if ($room->image_path) {
            Storage::disk('public')->delete($room->image_path);
        }
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

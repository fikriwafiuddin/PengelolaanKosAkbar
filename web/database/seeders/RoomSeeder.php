<?php

namespace Database\Seeders;

use App\Models\Facility;
use App\Models\Room;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Data 29 kamar Kost Akbar sesuai denah: Lantai 1 bertipe AC (9 kamar),
 * Lantai 2 & 3 bertipe Reguler (masing-masing 10 kamar).
 *
 * Total 29 kamar: 20 terisi + 9 kosong (mengikuti angka pada desain UI).
 */
class RoomSeeder extends Seeder
{
    /**
     * Konfigurasi per lantai: [tipe, harga, jumlah kamar, nomor awal].
     */
    private const FLOORS = [
        ['Lantai 1 - AC', 600000, 9, 1],
        ['Lantai 2 - Reguler', 500000, 10, 10],
        ['Lantai 3 - Reguler', 450000, 10, 20],
    ];

    /**
     * Fasilitas khas tiap tipe kamar.
     */
    private const FACILITIES_BY_TYPE = [
        'Lantai 1 - AC' => ['AC', 'KM Dalam', 'WiFi', 'Springbed', 'Meja & Kursi'],
        'Lantai 2 - Reguler' => ['Kipas Angin', 'KM Luar', 'WiFi', 'Kasur & Lemari', 'Jendela'],
        'Lantai 3 - Reguler' => ['Kipas Angin', 'KM Luar', 'WiFi', 'Kasur & Lemari'],
    ];

    public function run(): void
    {
        $facilities = Facility::query()->pluck('id', 'name');

        foreach (self::FLOORS as [$type, $price, $count, $startNumber]) {
            for ($i = 0; $i < $count; $i++) {
                $number = $startNumber + $i;

                $room = Room::query()->updateOrCreate(
                    ['room_number' => (string) $number],
                    [
                        'type' => $type,
                        'price_monthly' => $price,
                        'status' => 'kosong',
                        'description' => "Kamar {$type} ukuran 3x4 m, kapasitas 1 orang.",
                    ],
                );

                $room->facilities()->sync(
                    $facilities->only(self::FACILITIES_BY_TYPE[$type])->values()->all(),
                );
            }
        }

        // Tandai 20 kamar sebagai terisi (dipasangkan dengan penghuni
        // oleh ResidentSeeder): Lantai 1 -> 6 terisi, Lantai 2 -> 7,
        // Lantai 3 -> 7. Total 20 terisi, 9 kosong.
        $occupiedNumbers = [
            ...range(1, 6),      // Lantai 1
            ...range(10, 16),    // Lantai 2
            ...range(20, 26),    // Lantai 3
        ];

        Room::query()
            ->whereIn('room_number', array_map(strval(...), $occupiedNumbers))
            ->update(['status' => 'terisi']);
    }
}

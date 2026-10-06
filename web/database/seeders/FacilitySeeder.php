<?php

namespace Database\Seeders;

use App\Models\Facility;
use Illuminate\Database\Seeder;

/**
 * Master fasilitas kamar Kost Akbar.
 */
class FacilitySeeder extends Seeder
{
    /**
     * Fasilitas yang benar-benar tersedia di Kost Akbar.
     */
    private const FACILITIES = [
        'AC',
        'KM Dalam',
        'KM Luar',
        'WiFi',
        'Kasur & Lemari',
        'Springbed',
        'Kipas Angin',
        'Balkon',
        'Meja & Kursi',
        'Jendela',
    ];

    public function run(): void
    {
        foreach (self::FACILITIES as $name) {
            Facility::query()->updateOrCreate(['name' => $name]);
        }
    }
}

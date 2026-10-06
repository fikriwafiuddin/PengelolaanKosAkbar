<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed data demo Kost Akbar (Sprint 1).
     *
     * Urutan penting: admin & fasilitas dulu, lalu kamar, terakhir
     * penghuni yang menempati kamar-kamar terisi.
     */
    public function run(): void
    {
        $this->call([
            AdminUserSeeder::class,
            FacilitySeeder::class,
            RoomSeeder::class,
            ResidentSeeder::class,
        ]);
    }
}

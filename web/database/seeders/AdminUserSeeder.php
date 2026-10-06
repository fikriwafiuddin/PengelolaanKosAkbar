<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Akun admin (pengelola kos) untuk login dashboard web.
 */
class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@kostakbar.id'],
            [
                'name' => 'Ririn Yudarina',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'phone' => '+6281234567890',
                'email_verified_at' => now(),
            ],
        );
    }
}

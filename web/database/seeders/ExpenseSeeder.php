<?php

namespace Database\Seeders;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Pengeluaran operasional demo (Sprint 4): 3 bulan terakhir agar
 * laporan kas & laba bulanan langsung terisi.
 */
class ExpenseSeeder extends Seeder
{
    /**
     * Kategori + nominal dasar per bulan (divariasikan sedikit).
     */
    private const TEMPLATE = [
        ['category' => 'Listrik & Air', 'description' => 'Tagihan listrik kos bulanan', 'amount' => 1_450_000],
        ['category' => 'Kebersihan', 'description' => 'Gaji petugas kebersihan', 'amount' => 600_000],
        ['category' => 'Perawatan', 'description' => 'Servis AC & lampu kamar', 'amount' => 350_000],
        ['category' => 'Internet', 'description' => 'Langganan WiFi', 'amount' => 450_000],
    ];

    public function run(): void
    {
        $admin = User::query()->where('role', 'admin')->first();
        $adminId = $admin?->id ?? User::query()->value('id');

        foreach ([2, 1, 0] as $monthsAgo) {
            $base = now()->subMonths($monthsAgo)->startOfMonth();

            foreach (self::TEMPLATE as $index => $item) {
                // Variasi kecil agar tiap bulan berbeda (deterministik).
                $amount = $item['amount'] + ($monthsAgo * 50_000) + ($index * 25_000);
                $date = $base->copy()->day(5 + $index * 6);

                // Jangan mencatat tanggal masa depan.
                if ($date->isFuture()) {
                    $date = now()->subDay();
                }

                Expense::query()->updateOrCreate(
                    [
                        'expense_date' => $date->toDateString(),
                        'category' => $item['category'],
                        'description' => $item['description'],
                    ],
                    [
                        'amount' => $amount,
                        'created_by' => $adminId,
                    ],
                );
            }
        }
    }
}

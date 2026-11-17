<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Rekonsiliasi status lama → baru: sebelum status "belum_menyewa"
     * ada, semua akun tervalidasi diberi status "aktif" meskipun tidak
     * sedang menyewa. Ubah penghuni "aktif" tanpa sewa aktif menjadi
     * "belum_menyewa" agar status kini berarti "sedang menyewa".
     */
    public function up(): void
    {
        DB::table('users')
            ->where('role', 'penghuni')
            ->where('status', 'aktif')
            ->whereNotIn('id', function (Builder $query) {
                $query->select('residents.user_id')
                    ->from('residents')
                    ->join('bookings', 'bookings.resident_id', '=', 'residents.id')
                    ->where('bookings.status', 'aktif');
            })
            ->update([
                'status' => 'belum_menyewa',
                'updated_at' => now(),
            ]);
    }

    /**
     * Kembalikan semua "belum_menyewa" menjadi "aktif" (makna lama:
     * akun tervalidasi).
     */
    public function down(): void
    {
        DB::table('users')
            ->where('role', 'penghuni')
            ->where('status', 'belum_menyewa')
            ->update([
                'status' => 'aktif',
                'updated_at' => now(),
            ]);
    }
};

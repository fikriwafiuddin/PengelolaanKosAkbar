<?php

namespace App\Services;

use App\Models\Resident;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * Logika bisnis data penghuni: direktori biodata penghuni,
 * status akun (validasi admin), serta status pembayaran sewa
 * (dipakai ringkasan dashboard).
 */
class ResidentService
{
    /**
     * Direktori penghuni (biodata) dengan pencarian & filter.
     *
     * Filter yang didukung:
     * - q      : nama, NIK, atau nomor kamar
     * - status : status akun (aktif|menunggu_validasi|ditolak)
     */
    public function list(array $filters = [], int $perPage = 10): LengthAwarePaginator
    {
        return Resident::query()
            ->with(['user', 'activeBooking.room'])
            ->when($filters['q'] ?? null, function (Builder $query, string $q) {
                $query->where(function (Builder $inner) use ($q) {
                    $inner->where('full_name', 'like', "%{$q}%")
                        ->orWhere('identity_number', 'like', "%{$q}%")
                        ->orWhereHas('activeBooking.room', fn (Builder $r) => $r->where('room_number', 'like', "%{$q}%"));
                });
            })
            ->when($filters['status'] ?? null, fn (Builder $query, string $status) => $query->whereHas(
                'user',
                fn (Builder $u) => $u->where('status', $status),
            ))
            ->orderBy('full_name')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Aksi admin menvalidasi akun penghuni: setujui (aktif) atau tolak.
     *
     * Saat ditolak, seluruh token device akun tersebut dicabut agar
     * sesi yang sudah berjalan ikut berakhir.
     */
    public function validateAccount(User $user, string $status): void
    {
        $user->update(['status' => $status]);

        if ($status === User::STATUS_REJECTED) {
            $user->tokens()->delete();
        }
    }

    /**
     * Status pembayaran penghuni untuk bulan berjalan:
     * lunas | menunggu_verifikasi | belum_bayar | tanpa_tagihan
     *
     * Bekerja dengan relasi eager-loaded maupun lazy (collection).
     */
    public function paymentStatus(Resident $resident): string
    {
        $booking = $resident->activeBooking;

        if (! $booking) {
            return 'tanpa_tagihan';
        }

        $invoice = $booking->invoices->firstWhere('period', now()->format('Y-m'));

        // Belum ada tagihan untuk bulan ini (mis. sewa belum masuk siklus).
        if (! $invoice) {
            return 'lunas';
        }

        if ($invoice->payments->contains('status', 'pending')) {
            return 'menunggu_verifikasi';
        }

        return $invoice->status === 'lunas' ? 'lunas' : 'belum_bayar';
    }

    /**
     * Statistik penghuni untuk kartu ringkasan dashboard admin.
     */
    public function stats(): array
    {
        $residents = Resident::query()
            ->with(['activeBooking.invoices.payments'])
            ->has('activeBooking')
            ->get();

        $counts = ['lunas' => 0, 'menunggu_verifikasi' => 0, 'belum_bayar' => 0];
        foreach ($residents as $resident) {
            $status = $this->paymentStatus($resident);
            if (isset($counts[$status])) {
                $counts[$status]++;
            }
        }

        return [
            'total' => $residents->count(),
            'lunas' => $counts['lunas'],
            'menunggu_verifikasi' => $counts['menunggu_verifikasi'],
            'belum_bayar' => $counts['belum_bayar'],
        ];
    }
}

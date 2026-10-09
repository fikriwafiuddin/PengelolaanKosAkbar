<?php

namespace App\Services;

use App\Models\Resident;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * Logika bisnis data penghuni: direktori penghuni beserta status
 * pembayaran sewa bulan berjalan.
 */
class ResidentService
{
    /**
     * Direktori penghuni dengan pencarian & filter.
     *
     * Filter yang didukung:
     * - q            : nama, email, nomor kamar
     * - status       : lunas|menunggu_verifikasi|belum_bayar
     * - with_room    : 1 = hanya penghuni yang sedang menyewa
     */
    public function list(array $filters = [], int $perPage = 10): LengthAwarePaginator
    {
        // $query = Resident::query()
        //     ->with(['user', 'activeBooking.room', 'activeBooking.invoices.payments'])
        //     ->when($filters['q'] ?? null, function (Builder $query, string $q) {
        //         $query->where(function (Builder $inner) use ($q) {
        //             $inner->where('full_name', 'like', "%{$q}%")
        //                 ->orWhereHas('user', fn (Builder $u) => $u->where('email', 'like', "%{$q}%"))
        //                 ->orWhereHas('activeBooking.room', fn (Builder $r) => $r->where('room_number', 'like', "%{$q}%"));
        //         });
        //     })
        //     ->when(($filters['with_room'] ?? null) === '1', fn (Builder $query) => $query->whereHas('activeBooking'))
        //     ->orderBy('full_name');

        // Status pembayaran bukan kolom, melainkan diturunkan dari tagihan
        // bulan berjalan — karena itu difilter lewat daftar id penghuni yang
        // statusnya cocok (agar paginasi tetap akurat).
        // if ($statusFilter = $filters['status'] ?? null) {
        //     $matchingIds = (clone $query)->get()
        //         ->filter(fn (Resident $resident) => $this->paymentStatus($resident) === $statusFilter)
        //         ->pluck('id');

        //     $query->whereIn('id', $matchingIds);
        // }

        // $residents = $query->paginate($perPage)->withQueryString();

        // $residents->getCollection()->transform(function (Resident $resident) {
        //     $resident->payment_status = $this->paymentStatus($resident);

        //     return $resident;
        // });

        // return $residents;
        return Resident::query()
            ->with(['user', 'activeBooking.room'])
            ->when($filters['q'] ?? null, function (Builder $query, string $q) {
                $query->where(function (Builder $inner) use ($q) {
                    $inner->where('full_name', 'like', "%{$q}%")
                        ->orWhere('identity_number', 'like', "%{$q}%")
                        ->orWhereHas('activeBooking.room', fn (Builder $r) => $r->where('room_number', 'like', "%{$q}%"));
                });
            })
            ->orderBy('full_name')
            ->paginate($perPage)
            ->withQueryString();
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
     * Statistik penghuni untuk kartu ringkasan halaman Data Penghuni.
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

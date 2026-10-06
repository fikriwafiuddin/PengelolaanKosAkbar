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
        $query = Resident::query()
            ->with([
                'user' => fn ($user) => $user->select('id', 'name', 'email', 'phone'),
                'activeBooking.room' => fn ($room) => $room->select('id', 'room_number', 'type'),
            ])
            ->when($filters['q'] ?? null, function (Builder $query, string $q) {
                $query->where(function (Builder $inner) use ($q) {
                    $inner->where('full_name', 'like', "%{$q}%")
                        ->orWhereHas('user', fn (Builder $u) => $u->where('email', 'like', "%{$q}%"))
                        ->orWhereHas('activeBooking.room', fn (Builder $r) => $r->where('room_number', 'like', "%{$q}%"));
                });
            })
            ->when(($filters['with_room'] ?? null) === '1', fn (Builder $query) => $query->whereHas('activeBooking'))
            ->withCount(['bookings as active_bookings_count' => fn (Builder $b) => $b->where('status', 'aktif')])
            ->orderBy('full_name');

        // Filter status pembayaran dihitung setelah query (status tidak
        // disimpan langsung, melainkan diturunkan dari tagihan bulan ini).
        $residents = $query->paginate($perPage)->withQueryString();

        $statusFilter = $filters['status'] ?? null;
        $residents->getCollection()->transform(function (Resident $resident) {
            $resident->payment_status = $this->paymentStatus($resident);

            return $resident;
        });

        if ($statusFilter) {
            $filtered = $residents->getCollection()->where('payment_status', $statusFilter);
            $residents->setCollection($filtered->values());
        }

        return $residents;
    }

    /**
     * Status pembayaran penghuni untuk bulan berjalan:
     * lunas | menunggu_verifikasi | belum_bayar | tanpa_tagihan
     */
    public function paymentStatus(Resident $resident): string
    {
        $booking = $resident->activeBooking;

        if (! $booking) {
            return 'tanpa_tagihan';
        }

        $currentPeriod = now()->format('Y-m');

        $invoice = $booking->invoices()
            ->where('period', $currentPeriod)
            ->first();

        // Belum ada tagihan untuk bulan ini (mis. sewa belum masuk siklus).
        if (! $invoice) {
            return 'lunas';
        }

        if ($invoice->payments()->where('status', 'pending')->exists()) {
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
            ->with('activeBooking.room')
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

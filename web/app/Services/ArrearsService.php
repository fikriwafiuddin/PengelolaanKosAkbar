<?php

namespace App\Services;

use App\Models\Invoice;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;

/**
 * Logika bisnis data tunggakan pembayaran penghuni:
 * daftar tagihan belum lunas / lewat jatuh tempo, pencarian per penghuni / kamar,
 * dan kalkulasi total uang menunggak.
 */
class ArrearsService
{
    /**
     * Ambil daftar tagihan menunggak dengan filter.
     *
     * Filter:
     * - q: pencarian nama penghuni atau nomor kamar
     * - overdue_only: boolean (hanya yang sudah lewat jatuh tempo)
     * - period: filter periode YYYY-MM tertentu
     */
    public function list(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->baseQuery($filters)
            ->with(['booking.resident.user', 'booking.room'])
            ->orderBy('due_date')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Ringkasan statistik tunggakan untuk kartu ringkasan.
     */
    public function summary(array $filters = []): array
    {
        $base = $this->baseQuery($filters);

        $totalAmount = (float) (clone $base)->sum('amount');
        $totalInvoices = (int) (clone $base)->count();

        // Jumlah penghuni unik yang menunggak
        $residentCount = (int) (clone $base)
            ->join('bookings', 'invoices.booking_id', '=', 'bookings.id')
            ->distinct('bookings.resident_id')
            ->count('bookings.resident_id');

        // Khusus yang sudah lewat jatuh tempo
        $overdueAmount = (float) Invoice::query()
            ->where('invoices.status', 'belum_bayar')
            ->where('invoices.due_date', '<', now())
            ->sum('invoices.amount');

        $overdueCount = (int) Invoice::query()
            ->where('invoices.status', 'belum_bayar')
            ->where('invoices.due_date', '<', now())
            ->count();

        return [
            'total_amount' => $totalAmount,
            'total_amount_formatted' => 'Rp '.number_format($totalAmount, 0, ',', '.'),
            'total_invoices' => $totalInvoices,
            'resident_count' => $residentCount,
            'overdue_amount' => $overdueAmount,
            'overdue_amount_formatted' => 'Rp '.number_format($overdueAmount, 0, ',', '.'),
            'overdue_count' => $overdueCount,
        ];
    }

    /**
     * Query dasar tagihan yang belum lunas.
     */
    private function baseQuery(array $filters = []): Builder
    {
        return Invoice::query()
            ->where('invoices.status', 'belum_bayar')
            ->when(!empty($filters['overdue_only']), fn (Builder $q) => $q->where('invoices.due_date', '<', now()))
            ->when(!empty($filters['period']), fn (Builder $q) => $q->where('invoices.period', $filters['period']))
            ->when(!empty($filters['q']), function (Builder $query) use ($filters) {
                $q = $filters['q'];
                $query->where(function (Builder $inner) use ($q) {
                    $inner->whereHas('booking.resident', fn (Builder $r) => $r->where('full_name', 'like', "%{$q}%"))
                        ->orWhereHas('booking.resident.user', fn (Builder $u) => $u->where('name', 'like', "%{$q}%")->orWhere('phone', 'like', "%{$q}%"))
                        ->orWhereHas('booking.room', fn (Builder $rm) => $rm->where('room_number', 'like', "%{$q}%"));
                });
            });
    }
}


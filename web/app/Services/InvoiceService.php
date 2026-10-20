<?php

namespace App\Services;

use App\Models\Invoice;
use App\Models\Resident;
use App\Models\User;
use Illuminate\Support\Collection;

/**
 * Logika bisnis tagihan sewa bulanan: rincian tagihan milik
 * penghuni beserta ringkasan totalnya.
 */
class InvoiceService
{
    /**
     * Seluruh tagihan milik penghuni (terbaru duluan) + ringkasan
     * total tagihan dan sisa yang belum dibayar.
     *
     * @return array{invoices: Collection<int, Invoice>, summary: array<string, mixed>}
     */
    public function listForUser(User $user): array
    {
        $residentId = Resident::query()->where('user_id', $user->id)->value('id');

        $invoices = Invoice::query()
            ->whereHas('booking', fn ($query) => $query->where('resident_id', $residentId ?? 0))
            ->with(['booking.room', 'booking.resident.user', 'payments'])
            ->orderByDesc('period')
            ->get();

        $unpaid = $invoices->where('status', 'belum_bayar')->values();

        return [
            'invoices' => $invoices,
            'summary' => [
                'total_count' => $invoices->count(),
                'total_amount' => (float) $invoices->sum('amount'),
                'unpaid_count' => $unpaid->count(),
                'unpaid_amount' => (float) $unpaid->sum('amount'),
                'next_due_date' => $unpaid->min('due_date'),
            ],
        ];
    }

    /**
     * Ambil satu tagihan milik penghuni; 404 bila tagihan milik orang lain.
     */
    public function findForUser(User $user, Invoice $invoice): Invoice
    {
        $owned = Resident::query()
            ->where('user_id', $user->id)
            ->whereHas('bookings', fn ($query) => $query->whereKey($invoice->booking_id))
            ->exists();

        abort_unless($owned, 404, 'Tagihan tidak ditemukan.');

        return $invoice->load(['booking.room.facilities', 'booking.resident.user', 'payments' => fn ($query) => $query->latest('id')]);
    }
}

<?php

namespace App\Services;

use App\Models\Invoice;
use App\Models\Resident;
use App\Models\Room;
use Illuminate\Support\Collection;

/**
 * Logika penyusun data ringkasan dashboard admin.
 */
class DashboardService
{
    public function __construct(
        private readonly RoomService $rooms,
        private readonly ResidentService $residents,
        private readonly FinanceService $finance,
    ) {}

    /**
     * Seluruh angka ringkas yang ditampilkan di dashboard admin.
     * Mencakup grafik keuangan (Rev-3), penghuni belum bayar (Rev-4),
     * serta hitungan calon penghuni & alumni (Rev-5).
     */
    public function overview(): array
    {
        $roomStats     = $this->rooms->stats();
        $residentStats = $this->residents->stats();
        $currentMonth  = now()->format('Y-m');

        return [
            'rooms'          => $roomStats,
            'occupancy'      => $this->occupancy($roomStats['total'], $roomStats['terisi']),
            'residents'      => $residentStats,
            'trend'          => $this->finance->trend($currentMonth),   // Rev-3: grafik keuangan
            'overdue_unpaid' => $this->overdueUnpaid(),                 // Rev-4: penghuni terlambat bayar
            'latest_residents' => $this->latestResidents(),
        ];
    }

    /**
     * Persentase okupansi kamar.
     */
    private function occupancy(int $total, int $terisi): float
    {
        if ($total === 0) {
            return 0.0;
        }

        return round($terisi / $total * 100, 1);
    }

    /**
     * Daftar penghuni yang tagihan-nya sudah lewat jatuh tempo
     * tapi belum dibayar/terverifikasi (Rev-4).
     *
     * @return array<int, array<string, mixed>>
     */
    private function overdueUnpaid(): array
    {
        return Invoice::query()
            ->where('status', 'belum_bayar')
            ->where('due_date', '<', now())
            ->with([
                'booking.resident',
                'booking.room',
            ])
            ->orderBy('due_date')
            ->limit(10)
            ->get()
            ->map(fn (Invoice $invoice) => [
                'invoice_id'    => $invoice->id,
                'resident_name' => $invoice->booking?->resident?->full_name ?? '-',
                'room_number'   => $invoice->booking?->room?->room_number ?? '-',
                'period'        => $invoice->period,
                'period_label'  => $invoice->periodLabel(),
                'amount'        => (float) $invoice->amount,
                'amount_formatted' => 'Rp ' . number_format((float) $invoice->amount, 0, ',', '.'),
                'due_date'      => $invoice->due_date->toDateString(),
                'due_date_formatted' => $invoice->due_date->locale('id')->translatedFormat('d M Y'),
            ])
            ->all();
    }

    /**
     * Penghuni terbaru yang mulai menyewa (untuk panel aktivitas).
     */
    private function latestResidents(): Collection
    {
        return Resident::query()
            ->whereHas('activeBooking')
            ->with(['activeBooking.room'])
            ->latest('created_at')
            ->limit(6)
            ->get(['id', 'full_name', 'created_at'])
            ->map(fn (Resident $resident) => [
                'name'       => $resident->full_name,
                'room'       => $resident->activeBooking?->room?->room_number,
                'start_date' => $resident->activeBooking?->start_date?->format('d M Y'),
            ]);
    }
}

<?php

namespace App\Services;

use App\Models\Invoice;
use App\Models\Resident;
use App\Models\Room;

/**
 * Logika penyusun data ringkasan dashboard admin.
 * Murni mengagregasi data ringkasan, metrik KPI, grafik, dan total keuangan/tunggakan.
 * Tidak mencampur data mentah (tabel/daftar rinci dialihkan ke menu terkait).
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
     * Termasuk ringkasan keuangan, metrik tunggakan, okupansi, dan grafik tren 6 bulan.
     */
    public function overview(): array
    {
        $roomStats     = $this->rooms->stats();
        $residentStats = $this->residents->stats();
        $currentMonth  = now()->format('Y-m');

        // Ringkasan Keuangan
        $financeSummary = $this->finance->summary($currentMonth);

        // Ringkasan Tunggakan
        $overdueQuery = Invoice::query()->where('invoices.status', 'belum_bayar');
        $totalArrears = (float) (clone $overdueQuery)->sum('invoices.amount');
        $totalOverdueInvoices = (int) (clone $overdueQuery)->count();
        $residentArrearsCount = (int) (clone $overdueQuery)
            ->join('bookings', 'invoices.booking_id', '=', 'bookings.id')
            ->distinct('bookings.resident_id')
            ->count('bookings.resident_id');

        return [
            'rooms'            => $roomStats,
            'occupancy'        => $this->occupancy($roomStats['total'], $roomStats['terisi']),
            'residents'        => $residentStats,
            'finance_summary'  => $financeSummary,
            'trend'            => $this->finance->trend($currentMonth),
            'arrears_summary'  => [
                'total_amount' => $totalArrears,
                'total_amount_formatted' => 'Rp '.number_format($totalArrears, 0, ',', '.'),
                'total_invoices' => $totalOverdueInvoices,
                'resident_count' => $residentArrearsCount,
            ],
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
}

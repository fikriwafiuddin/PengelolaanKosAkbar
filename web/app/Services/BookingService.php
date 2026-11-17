<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\Invoice;
use App\Models\Resident;
use App\Models\Room;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Logika bisnis pemesanan kamar: pembuatan pemesanan, pembuatan
 * tagihan sewa bulanan otomatis, dan riwayat pemesanan penghuni.
 */
class BookingService
{
    /**
     * Tanggal jatuh tempo tagihan sewa setiap tanggal 25.
     */
    public const DUE_DAY = 25;

    /**
     * Riwayat pemesanan milik satu penghuni (terbaru duluan).
     *
     * @return Collection<int, Booking>
     */
    public function listForUser(User $user): Collection
    {
        $residentId = Resident::query()->where('user_id', $user->id)->value('id');

        return Booking::query()
            ->where('resident_id', $residentId ?? 0)
            ->with(['invoices', 'room'])
            ->orderByDesc('start_date')
            ->get();
    }

    /**
     * Buat pemesanan baru: kamar langsung terisi dan tagihan sewa
     * bulanan dibuat otomatis sesuai tanggal mulai + durasi sewa.
     *
     * @param  array{room_id: int, start_date: string, duration_months: int, note?: string|null}  $data
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function create(User $user, array $data): Booking
    {
        $room = Room::query()->findOrFail($data['room_id']);
        $resident = Resident::query()->where('user_id', $user->id)->first();

        $this->assertBookable($user, $resident, $room);

        $startDate = Carbon::parse($data['start_date']);

        $booking = DB::transaction(function () use ($resident, $room, $data, $startDate) {
            $booking = Booking::query()->create([
                'resident_id' => $resident->id,
                'room_id' => $room->id,
                'start_date' => $startDate->toDateString(),
                'duration_months' => $data['duration_months'],
                'status' => 'aktif',
                'note' => $data['note'] ?? null,
            ]);

            $room->update(['status' => 'terisi']);

            // Penghuni kini sedang menyewa — status akun ikut aktif.
            $resident->user?->update(['status' => User::STATUS_ACTIVE]);

            $this->createInvoices($booking, $room, $startDate, (int) $data['duration_months']);

            return $booking;
        });

        return $booking->load(['room.facilities', 'invoices']);
    }

    /**
     * Pastikan pemesanan boleh dilakukan: kamar tersedia dan penghuni
     * belum menyewa kamar lain secara aktif.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    private function assertBookable(User $user, ?Resident $resident, Room $room): void
    {
        $errors = [];

        if ($room->status !== 'kosong') {
            $errors['room_id'] = 'Kamar nomor '.$room->room_number.' tidak tersedia untuk dipesan.';
        }

        $hasActiveBooking = Booking::query()
            ->where('resident_id', $resident?->id ?? 0)
            ->whereIn('status', ['menunggu', 'aktif'])
            ->exists();

        if ($hasActiveBooking) {
            $errors['room_id'] = 'Anda masih memiliki pemesanan aktif. Batalkan atau selesaikan dulu sebelum memesan kamar lain.';
        }

        if ($errors) {
            throw ValidationException::withMessages($errors);
        }
    }

    /**
     * Buat tagihan sewa untuk setiap bulan durasi sewa: periode
     * YYYY-MM, nominal = harga kamar per bulan, jatuh tempo tanggal 25
     * (digeser ke bulan berikutnya bila tanggal mulai melewati tanggal 25).
     */
    private function createInvoices(Booking $booking, Room $room, Carbon $startDate, int $durationMonths): void
    {
        for ($month = 0; $month < $durationMonths; $month++) {
            $period = $startDate->copy()->addMonths($month)->startOfMonth();
            $dueDate = $period->copy()->day(self::DUE_DAY);

            if ($dueDate->lessThan($startDate)) {
                $dueDate->addMonth();
            }

            Invoice::query()->create([
                'booking_id' => $booking->id,
                'period' => $period->format('Y-m'),
                'amount' => $room->price_monthly,
                'due_date' => $dueDate->toDateString(),
                'status' => 'belum_bayar',
            ]);
        }
    }

    /**
     * Akhiri sewa (keluar kost): status pemesanan jadi 'selesai' dan
     * kamar dikosongkan bila tidak ada penghuni aktif lain di kamar itu.
     * Ditolak bila masih ada tagihan yang belum lunas.
     */
    public function leave(Booking $booking, User $user): Booking
    {
        // hanya pemilik sewa yang boleh mengakhiri sewanya
        abort_unless($booking->resident?->user_id === $user->id, 403, 'Anda tidak berhak mengakhiri sewa ini.');

        if ($booking->status !== 'aktif') {
            throw ValidationException::withMessages([
                'booking' => 'Sewa ini sudah tidak aktif.',
            ]);
        }

        // Aturan: penghuni wajib melunasi semua tagihan sebelum keluar kost.
        $adaTunggakan = $booking->invoices()->where('status', '!=', 'lunas')->exists();
        if ($adaTunggakan) {
            throw ValidationException::withMessages([
                'booking' => 'Lunasi tagihan yang belum dibayar sebelum keluar dari kost.',
            ]);
        }

        return DB::transaction(function () use ($booking) {
            $booking->update(['status' => 'selesai']);

            // Kamar bisa dihuni lebih dari satu orang (mis. kamar 27)
            $masihDihuni = Booking::where('room_id', $booking->room_id)
                ->where('status', 'aktif')
                ->where('id', '!=', $booking->id)
                ->exists();

            if (! $masihDihuni) {
                $booking->room()->update(['status' => 'kosong']);
            }

            // Status akun kembali "belum menyewa" bila tidak ada sewa
            // aktif lain milik penghuni ini.
            $masihMenyewa = Booking::query()
                ->where('resident_id', $booking->resident_id)
                ->where('status', 'aktif')
                ->where('id', '!=', $booking->id)
                ->exists();

            if (! $masihMenyewa) {
                $booking->resident?->user?->update(['status' => User::STATUS_NOT_RENTING]);
            }

            return $booking->fresh(['room']);
        });
    }
}

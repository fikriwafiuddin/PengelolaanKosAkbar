<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\Resident;
use App\Models\Room;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * 20 penghuni aktif beserta akun, pemesanan, tagihan, dan pembayaran.
 *
 * Distribusi status pembayaran bulan Oktober 2026 (mengikuti desain UI):
 * 16 lunas, 1 menunggu verifikasi, 3 belum bayar.
 */
class ResidentSeeder extends Seeder
{
    /**
     * Nama 20 penghuni aktif (3 nama pertama sesuai contoh pada desain UI).
     */
    private const RESIDENTS = [
        'Dimas Pratama', 'Bagas Wicaksono', 'Fajar Nugraha', 'Andi Saputra',
        'Rizky Ramadhan', 'Bayu Setiawan', 'Gilang Prakoso', 'Hendra Wijaya',
        'Irfan Maulana', 'Krisna Adi', 'Lutfi Hakim', 'Mahesa Dewangga',
        'Naufal Arkan', 'Oscar Pratama', 'Panji Setiawan', 'Reza Fahlevi',
        'Satria Wibowo', 'Tegar Nugroho', 'Umar Faruq', 'Vino Bastian',
    ];

    /**
     * Index penghuni dengan status pembayaran khusus bulan ini
     * (sisanya dianggap lunas).
     */
    private const PENDING_VERIFICATION_INDEX = 16;
    private const UNPAID_INDEXES = [17, 18, 19];

    public function run(): void
    {
        $occupiedRooms = Room::query()
            ->where('status', 'terisi')
            ->orderBy('room_number')
            ->get();

        $receiptCounter = 1;

        foreach (self::RESIDENTS as $index => $fullName) {
            $room = $occupiedRooms[$index];

            [$user, $resident] = $this->createUserAndResident($index, $fullName);

            $booking = $this->createActiveBooking($resident, $room, $index);

            // Tagihan dua bulan sebelum bulan ini sudah lunas semua,
            // tagihan bulan berjalan mengikuti skenario status.
            $receiptCounter = $this->createInvoiceHistory($booking, $room, $index, $receiptCounter);
        }
    }

    /**
     * Buat akun login + profil identitas penghuni.
     *
     * @return array{0: User, 1: Resident}
     */
    private function createUserAndResident(int $index, string $fullName): array
    {
        $slug = strtolower(str_replace(' ', '', $fullName));

        $user = User::query()->updateOrCreate(
            ['email' => "{$slug}@kostakbar.id"],
            [
                'name' => $fullName,
                'password' => Hash::make('password'),
                'role' => 'penghuni',
                'phone' => '+62812'.str_pad((string) (3000000000 + $index * 137), 10, '0', STR_PAD_LEFT),
                'email_verified_at' => now(),
            ],
        );

        $resident = Resident::query()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'full_name' => $fullName,
                'identity_number' => '35'.str_pad((string) (7300000000000000 + $index * 4241), 14, '0', STR_PAD_LEFT),
                'birth_date' => now()->subYears(20 + $index % 8)->subMonths($index % 12)->startOfMonth(),
                'address' => 'Kota Kediri, Jawa Timur',
                'occupation' => $index % 3 === 0 ? 'Mahasiswa' : ($index % 3 === 1 ? 'Karyawan' : 'Wirausaha'),
            ],
        );

        return [$user, $resident];
    }

    /**
     * Pemesanan aktif untuk kamar yang ditempati.
     */
    private function createActiveBooking(Resident $resident, Room $room, int $index): Booking
    {
        return Booking::query()->updateOrCreate(
            ['resident_id' => $resident->id, 'room_id' => $room->id, 'status' => 'aktif'],
            [
                'start_date' => now()->subMonths(6 + $index)->startOfMonth(),
                'duration_months' => 12,
                'note' => 'Perpanjangan otomatis bulanan.',
            ],
        );
    }

    /**
     * Tagihan Agustus & September (lunas) + Oktober (sesuai skenario).
     */
    private function createInvoiceHistory(Booking $booking, Room $room, int $index, int $receiptCounter): int
    {
        // Dua bulan terakhir: lunas + pembayaran terverifikasi.
        foreach ([2, 1] as $monthsAgo) {
            $date = now()->subMonths($monthsAgo);

            $invoice = Invoice::query()->updateOrCreate(
                ['booking_id' => $booking->id, 'period' => $date->format('Y-m')],
                [
                    'amount' => $room->price_monthly,
                    'due_date' => $date->copy()->day(25),
                    'status' => 'lunas',
                ],
            );

            $this->createVerifiedPayment($invoice, $booking, $receiptCounter++);
        }

        // Bulan berjalan: sesuai skenario status per penghuni.
        $current = Invoice::query()->updateOrCreate(
            ['booking_id' => $booking->id, 'period' => now()->format('Y-m')],
            [
                'amount' => $room->price_monthly,
                'due_date' => now()->copy()->day(25),
                'status' => 'belum_bayar',
            ],
        );

        if (in_array($index, self::UNPAID_INDEXES, true)) {
            // Skenario belum bayar: tanpa pembayaran sama sekali.
            return $receiptCounter;
        }

        if ($index === self::PENDING_VERIFICATION_INDEX) {
            // Skenario menunggu verifikasi: sudah bayar, belum diperiksa admin.
            Payment::query()->updateOrCreate(
                ['invoice_id' => $current->id],
                [
                    'user_id' => $booking->resident->user_id,
                    'amount' => $room->price_monthly,
                    'method' => 'transfer',
                    'proof_path' => 'bukti/demo-transfer.png',
                    'status' => 'pending',
                    'paid_at' => now()->subDay(),
                ],
            );

            return $receiptCounter;
        }

        // Skenario lunas.
        $current->update(['status' => 'lunas']);
        $this->createVerifiedPayment($current, $booking, $receiptCounter++);

        return $receiptCounter;
    }

    /**
     * Pembayaran terverifikasi admin (untuk tagihan yang sudah lunas).
     */
    private function createVerifiedPayment(Invoice $invoice, Booking $booking, int $receiptCounter): Payment
    {
        return Payment::query()->updateOrCreate(
            ['invoice_id' => $invoice->id],
            [
                'user_id' => $booking->resident->user_id,
                'amount' => $invoice->amount,
                'method' => $receiptCounter % 4 === 0 ? 'tunai' : 'transfer',
                'receipt_no' => 'KA-'.now()->format('Y').'-'.str_pad((string) $receiptCounter, 4, '0', STR_PAD_LEFT),
                'status' => 'terverifikasi',
                'verified_by' => User::query()->where('role', 'admin')->value('id'),
                'paid_at' => $invoice->due_date->copy()->subDays(3),
                'verified_at' => $invoice->due_date->copy()->subDays(2),
            ],
        );
    }
}

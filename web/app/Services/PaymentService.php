<?php

namespace App\Services;

use App\Models\Invoice;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

/**
 * Logika bisnis pembayaran sewa: pengiriman bukti bayar oleh penghuni,
 * verifikasi oleh admin, penomoran kuitansi, dan daftar verifikasi.
 */
class PaymentService
{
    public function __construct(private readonly FcmService $fcm)
    {}
    /**
     * Kirim pembayaran untuk satu tagihan: nominal + bukti transfer,
     * status pending sampai diverifikasi admin.
     *
     * @param  array{amount: float, method: string}  $data
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function submit(User $user, Invoice $invoice, array $data, ?UploadedFile $proof): Payment
    {
        $errors = [];

        if ($invoice->status !== 'belum_bayar') {
            $errors['invoice_id'] = 'Tagihan periode '.$invoice->period.' sudah lunas.';
        }

        $hasPendingPayment = $invoice->payments()->where('status', 'pending')->exists();

        if ($hasPendingPayment) {
            $errors['invoice_id'] = 'Masih ada pembayaran yang menunggu verifikasi untuk tagihan ini.';
        }

        if ((float) $data['amount'] > (float) $invoice->amount) {
            $errors['amount'] = 'Nominal melebihi total tagihan (maks Rp '.number_format((float) $invoice->amount, 0, ',', '.').').';
        }

        if ($errors) {
            throw ValidationException::withMessages($errors);
        }

        return Payment::query()->create([
            'invoice_id' => $invoice->id,
            'user_id' => $user->id,
            'amount' => $data['amount'],
            'method' => $data['method'],
            'proof_path' => $proof?->store('payments', 'public'),
            'status' => 'pending',
            'paid_at' => now(),
        ]);
    }

    /**
     * Daftar pembayaran untuk halaman Verifikasi Pembayaran admin
     * sekaligus riwayat transaksi pembayaran penghuni.
     *
     * Filter:
     * - status : pending|terverifikasi|ditolak|semua (default pending)
     * - month  : periode tagihan YYYY-MM (mis. 2026-10)
     * - q      : nomor kamar / nama penghuni
     */
    public function list(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return Payment::query()
            ->with(['invoice.booking.room', 'invoice.booking.resident.user', 'verifier'])
            ->when(
                ($filters['status'] ?? 'pending') && ($filters['status'] ?? 'pending') !== 'semua',
                fn (Builder $query) => $query->where('status', $filters['status'] ?? 'pending'),
            )
            ->when($filters['month'] ?? null, fn (Builder $query, string $month) => $query->whereHas(
                'invoice',
                fn (Builder $invoice) => $invoice->where('period', $month),
            ))
            ->when($filters['q'] ?? null, fn (Builder $query, string $q) => $query->where(function (Builder $inner) use ($q) {
                $inner->whereHas('invoice.booking.room', fn (Builder $room) => $room->where('room_number', 'like', "%{$q}%"))
                    ->orWhereHas('invoice.booking.resident.user', fn (Builder $user) => $user->where('name', 'like', "%{$q}%"));
            }))
            ->orderByDesc('paid_at')
            ->paginate($perPage)
            ->withQueryString();
    }

    /**
     * Total nominal pembayaran terverifikasi sesuai filter aktif —
     * ringkasan untuk tab riwayat transaksi.
     */
    public function verifiedTotal(array $filters = []): float
    {
        return (float) Payment::query()
            ->where('status', 'terverifikasi')
            ->when($filters['month'] ?? null, fn (Builder $query, string $month) => $query->whereHas(
                'invoice',
                fn (Builder $invoice) => $invoice->where('period', $month),
            ))
            ->when($filters['q'] ?? null, fn (Builder $query, string $q) => $query->where(function (Builder $inner) use ($q) {
                $inner->whereHas('invoice.booking.room', fn (Builder $room) => $room->where('room_number', 'like', "%{$q}%"))
                    ->orWhereHas('invoice.booking.resident.user', fn (Builder $user) => $user->where('name', 'like', "%{$q}%"));
            }))
            ->sum('amount');
    }

    /**
     * Ambil satu pembayaran lengkap dengan relasi untuk kuitansi.
     */
    public function find(Payment $payment): Payment
    {
        return $payment->load(['invoice.booking.room', 'invoice.booking.resident.user', 'verifier']);
    }

    /**
     * Jumlah pembayaran per status untuk tab halaman verifikasi.
     *
     * @return array<string, int>
     */
    public function statusCounts(): array
    {
        return Payment::query()
            ->select('status')
            ->selectRaw('COUNT(*) AS total')
            ->groupBy('status')
            ->pluck('total', 'status')
            ->all();
    }

    /**
     * Verifikasi pembayaran oleh admin: terverifikasi (tagihan lunas +
     * kuitansi bernomor) atau ditolak (tagihan tetap belum bayar).
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function verify(Payment $payment, User $admin, string $status): Payment
    {
        if ($payment->status !== 'pending') {
            throw ValidationException::withMessages([
                'status' => 'Pembayaran ini sudah diverifikasi sebelumnya.',
            ]);
        }

        return DB::transaction(function () use ($payment, $admin, $status) {
            $payment->update([
                'status' => $status,
                'verified_by' => $admin->id,
                'verified_at' => now(),
                'receipt_no' => $status === 'terverifikasi' ? $this->nextReceiptNumber() : null,
            ]);

            if ($status === 'terverifikasi') {
                $payment->invoice->update(['status' => 'lunas']);
            }

            $this->notifyVerification($payment);

            return $payment->refresh();
        });
    }

    /**
     * Push FCM hasil verifikasi ke penghuni yang membayar (bila
     * Firebase dikonfigurasi).
     */
    private function notifyVerification(Payment $payment): void
    {
        if (! $this->fcm->enabled()) {
            return;
        }

        $resident = $payment->invoice->booking?->resident?->user;

        if (! $resident) {
            return;
        }

        $approved = $payment->status === 'terverifikasi';

        $this->fcm->sendToUser(
            $resident,
            $approved ? 'Pembayaran diterima' : 'Pembayaran ditolak',
            $approved
                ? 'Pembayaran Rp '.number_format((float) $payment->amount, 0, ',', '.')
                    .' telah diverifikasi. Kuitansi '.$payment->receipt_no.' terbit.'
                : 'Pembayaran Anda ditolak pengelola. Silakan periksa tagihan di aplikasi.',
            [
                'type' => 'payment',
                'payment_id' => (string) $payment->id,
                'status' => $payment->status,
            ],
        );
    }

    /**
     * Nomor kuitansi berurutan per tahun: KA-2026-0001, KA-2026-0002, ...
     */
    private function nextReceiptNumber(): string
    {
        $year = now()->format('Y');

        // Nomor selalu 4 digit berawalan nol, jadi urutan teks = urutan angka.
        $lastReceipt = Payment::query()
            ->where('receipt_no', 'like', "KA-{$year}-%")
            ->orderByDesc('receipt_no')
            ->value('receipt_no');

        $lastNumber = $lastReceipt ? (int) substr($lastReceipt, -4) : 0;

        return 'KA-'.$year.'-'.str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    /**
     * Hapus berkas bukti bayar dari disk public (aman bila kosong).
     */
    public function deleteProofFile(Payment $payment): void
    {
        if ($payment->proof_path) {
            Storage::disk('public')->delete($payment->proof_path);
        }
    }
}

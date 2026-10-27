<?php

namespace App\Console\Commands;

use App\Models\Invoice;
use App\Notifications\PaymentDueReminder;
use App\Services\FcmService;
use Illuminate\Console\Command;

/**
 * Kirim pengingat pembayaran untuk tagihan yang belum dibayar dan
 * mendekati / melewati jatuh tempo (jalankan harian lewat scheduler,
 * atau manual: php artisan payments:remind).
 */
class RemindDueInvoices extends Command
{
    public function __construct(private readonly FcmService $fcm)
    {
        parent::__construct();
    }

    protected $signature = 'payments:remind {--days=5 : Berapa hari ke depan jatuh tempo diingatkan}';

    protected $description = 'Kirim notifikasi pengingat tagihan sewa yang belum dibayar (mendekati / lewat jatuh tempo)';

    public function handle(): int
    {
        $days = max(0, (int) $this->option('days'));

        $invoices = Invoice::query()
            ->where('status', 'belum_bayar')
            ->where(function ($query) use ($days) {
                // Segera jatuh tempo dalam N hari ke depan...
                $query->whereBetween('due_date', [today(), today()->addDays($days)]);
                // ...atau sudah melewati jatuh tempo (ditagih ulang).
                $query->orWhere('due_date', '<', today());
            })
            // Lewati tagihan yang bayarannya sudah dikirim dan sedang
            // menunggu verifikasi admin — tidak perlu ditagih ulang.
            ->whereDoesntHave('payments', fn ($query) => $query->where('status', 'pending'))
            ->with('booking.room', 'booking.resident.user')
            ->get();

        $sent = 0;

        foreach ($invoices as $invoice) {
            $user = $invoice->booking?->resident?->user;

            if (! $user || ! $user->isActive()) {
                continue;
            }

            // Satu penghuni hanya dikirimi satu pengingat per tagihan.
            $alreadyReminded = $user->notifications()
                ->where('type', PaymentDueReminder::class)
                ->whereJsonContains('data->invoice_id', $invoice->id)
                ->exists();

            if ($alreadyReminded) {
                continue;
            }

            $reminder = new PaymentDueReminder($invoice);
            $user->notify($reminder);

            // Push FCM (bila Firebase dikonfigurasi) — muncul sebagai
            // notifikasi sistem walau aplikasi tertutup.
            $data = $reminder->toArray($user);

            $this->fcm->sendToUser(
                $user,
                $data['title'],
                $data['body'],
                [
                    'type' => 'reminder',
                    'invoice_id' => (string) $invoice->id,
                    'room_number' => (string) $data['room_number'],
                ],
            );

            $sent++;
        }

        $this->info("Pengingat terkirim: {$sent} dari {$invoices->count()} tagihan tertunggak.");

        return self::SUCCESS;
    }
}

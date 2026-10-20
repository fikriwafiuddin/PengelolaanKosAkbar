<?php

namespace App\Notifications;

use App\Models\Invoice;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

/**
 * Notifikasi pengingat jatuh tempo tagihan sewa (dikirim ke penghuni,
 * tersimpan di database dan dibaca aplikasi mobile).
 */
class PaymentDueReminder extends Notification
{
    /** @use Queueable<\Illuminate\Bus\Queueable> */
    use Queueable;

    public function __construct(private readonly Invoice $invoice)
    {}

    /**
     * Kanal pengiriman: simpan di database (diambil mobile lewat API
     * /notifications).
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Data yang disimpan: cukup untuk ditampilkan & membuka tagihan
     * terkait langsung dari aplikasi mobile.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $room = $this->invoice->booking?->room;
        $dueDate = $this->invoice->due_date->locale('id')->translatedFormat('d F Y');
        $isOverdue = $this->invoice->isOverdue();

        return [
            'title' => $isOverdue
                ? 'Tagihan sewa melewati jatuh tempo'
                : 'Pengingat jatuh tempo tagihan sewa',
            'body' => $isOverdue
                ? "Tagihan sewa Kamar {$room?->room_number} periode {$this->invoice->periodLabel()} sudah melewati jatuh tempo {$dueDate}. Segera lakukan pembayaran."
                : "Tagihan sewa Kamar {$room?->room_number} periode {$this->invoice->periodLabel()} jatuh tempo pada {$dueDate}. Segera lakukan pembayaran.",
            'invoice_id' => $this->invoice->id,
            'period' => $this->invoice->period,
            'period_label' => $this->invoice->periodLabel(),
            'due_date' => $this->invoice->due_date->toDateString(),
            'room_number' => $room?->room_number,
            'amount' => (float) $this->invoice->amount,
        ];
    }
}

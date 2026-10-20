<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Payment
 */
class PaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'invoice_id' => $this->invoice_id,
            'amount' => (float) $this->amount,
            'amount_formatted' => 'Rp '.number_format((float) $this->amount, 0, ',', '.'),
            'method' => $this->method,
            'method_label' => $this->methodLabel(),
            // URL relatif (/storage/payments/xxx.png); klien tinggal
            // menggabungkan dengan host masing-masing.
            'proof_url' => $this->proof_path ? '/storage/'.$this->proof_path : null,
            'receipt_no' => $this->receipt_no,
            'status' => $this->status,
            'status_label' => $this->statusLabel(),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'paid_at_formatted' => $this->paid_at?->locale('id')->translatedFormat('d F Y, H:i'),
            'verified_at' => $this->verified_at?->toIso8601String(),
            'verified_at_formatted' => $this->verified_at?->locale('id')->translatedFormat('d F Y'),
            'verifier_name' => $this->when($this->relationLoaded('verifier'), fn () => $this->verifier?->name),
            // Ringkasan tagihan terkait (dipakai halaman verifikasi admin).
            'invoice' => $this->when($this->relationLoaded('invoice'), fn () => [
                'id' => $this->invoice?->id,
                'period' => $this->invoice?->period,
                'period_label' => $this->invoice?->periodLabel(),
                'amount' => (float) $this->invoice?->amount,
                'amount_formatted' => 'Rp '.number_format((float) $this->invoice?->amount, 0, ',', '.'),
                'status' => $this->invoice?->status,
                'status_label' => $this->invoice?->statusLabel(),
                'due_date_formatted' => $this->invoice?->due_date?->locale('id')->translatedFormat('d F Y'),
            ]),
            'resident_name' => $this->when(
                $this->relationLoaded('invoice') && $this->invoice?->relationLoaded('booking'),
                fn () => $this->invoice?->booking?->resident?->full_name
                    ?? $this->invoice?->booking?->resident?->user?->name,
            ),
            'user_name' => $this->whenLoaded('user', fn () => $this->user?->name),
            'room_number' => $this->when(
                $this->relationLoaded('invoice') && $this->invoice?->relationLoaded('booking'),
                fn () => $this->invoice?->booking?->room?->room_number,
            ),
        ];
    }
}

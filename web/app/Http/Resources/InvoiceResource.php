<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Invoice
 */
class InvoiceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->booking_id,
            'period' => $this->period,
            'period_label' => $this->periodLabel(),
            'amount' => (float) $this->amount,
            'amount_formatted' => 'Rp '.number_format((float) $this->amount, 0, ',', '.'),
            'due_date' => $this->due_date->toDateString(),
            'due_date_formatted' => $this->due_date->locale('id')->translatedFormat('d F Y'),
            'status' => $this->status,
            'status_label' => $this->statusLabel(),
            'is_overdue' => $this->isOverdue(),
            'room' => $this->when($this->relationLoaded('booking'), fn () => [
                'id' => $this->booking?->room?->id,
                'room_number' => $this->booking?->room?->room_number,
                'type' => $this->booking?->room?->type,
                'price_monthly' => (float) $this->booking?->room?->price_monthly,
                'price_formatted' => 'Rp '.number_format((float) $this->booking?->room?->price_monthly, 0, ',', '.'),
            ]),
            'duration_months' => $this->whenLoaded('booking', fn () => $this->booking?->duration_months),
            'start_date' => $this->whenLoaded('booking', fn () => $this->booking?->start_date?->toDateString()),
            'payments' => PaymentResource::collection($this->whenLoaded('payments')),
        ];
    }
}

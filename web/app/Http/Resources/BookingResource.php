<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Booking
 */
class BookingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'room' => [
                'id' => $this->room?->id,
                'room_number' => $this->room?->room_number,
                'type' => $this->room?->type,
                'price_monthly' => (float) $this->room?->price_monthly,
                'price_formatted' => 'Rp '.number_format((float) $this->room?->price_monthly, 0, ',', '.'),
            ],
            'start_date' => $this->start_date->toDateString(),
            'start_date_formatted' => $this->start_date->locale('id')->translatedFormat('d F Y'),
            'duration_months' => $this->duration_months,
            'status' => $this->status,
            'status_label' => $this->statusLabel(),
            'note' => $this->note,
            'total_amount' => $this->when(
                $this->relationLoaded('invoices'),
                fn () => (float) $this->invoices->sum('amount'),
            ),
            'total_amount_formatted' => $this->when(
                $this->relationLoaded('invoices'),
                fn () => 'Rp '.number_format((float) $this->invoices->sum('amount'), 0, ',', '.'),
            ),
            'invoices' => InvoiceResource::collection($this->whenLoaded('invoices')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}

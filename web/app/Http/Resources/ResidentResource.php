<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Resident
 */
class ResidentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'full_name' => $this->full_name,
            'identity_number' => $this->identity_number,
            'birth_date' => $this->birth_date?->format('Y-m-d'),
            'address' => $this->address,
            'occupation' => $this->occupation,
            'room' => $this->whenLoaded('activeBooking', fn () => [
                'room_number' => $this->activeBooking?->room?->room_number,
                'type' => $this->activeBooking?->room?->type,
                'start_date' => $this->activeBooking?->start_date?->format('Y-m-d'),
                'duration_months' => $this->activeBooking?->duration_months,
            ]),
        ];
    }
}

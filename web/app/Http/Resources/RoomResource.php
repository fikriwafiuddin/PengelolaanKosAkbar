<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Room
 */
class RoomResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'room_number' => $this->room_number,
            'type' => $this->type,
            'price_monthly' => (float) $this->price_monthly,
            'price_formatted' => 'Rp '.number_format((float) $this->price_monthly, 0, ',', '.'),
            'status' => $this->status,
            'status_label' => $this->statusLabel(),
            'description' => $this->description,
            // URL relatif (/storage/rooms/xxx.png); klien mobile tinggal
            // menggabungkan dengan base URL API-nya.
            'image_url' => $this->when($this->image_path, $this->image_url),
            'facilities' => FacilityResource::collection($this->whenLoaded('facilities')),
        ];
    }
}

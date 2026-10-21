<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Message
 */
class MessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'chat_room_id' => $this->chat_room_id,
            'body' => $this->body,
            'is_announcement' => $this->is_announcement,
            'sent_at' => $this->created_at?->toIso8601String(),
            'sent_at_formatted' => $this->created_at?->locale('id')->translatedFormat('d F Y, H:i'),
            // true bila pesan ini dikirim oleh pengguna yang sedang login.
            'is_own' => $this->when(
                $request->user() !== null,
                fn () => $this->user_id === $request->user()->id,
            ),
            'sender' => $this->when($this->relationLoaded('user'), fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'role' => $this->user?->role,
            ]),
        ];
    }
}

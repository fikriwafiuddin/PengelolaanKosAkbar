<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\ChatRoom
 */
class ChatRoomResource extends JsonResource
{
    /**
     * @param  array<int, int>|null  $unreadCounts
     */
    public function __construct($resource, private readonly ?array $unreadCounts = null)
    {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $lastMessage = $this->messages->first();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'members_count' => $this->whenCounted('members') ?? $this->members->count(),
            'unread_count' => $this->unreadCounts[$this->id] ?? 0,
            'last_message' => $this->when($lastMessage !== null, fn () => $lastMessage ? [
                'body' => \Str::limit($lastMessage->body, 80),
                'is_announcement' => $lastMessage->is_announcement,
                'sender_name' => $lastMessage->user?->name,
                'sent_at_formatted' => $lastMessage->created_at?->locale('id')->translatedFormat('d F Y, H:i'),
            ] : null),
        ];
    }
}

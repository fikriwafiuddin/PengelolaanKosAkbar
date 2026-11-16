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
            'is_complaint_room' => str_starts_with($this->name, 'Laporan & Keluhan'),
            'members_count' => $this->whenCounted('members') ?? $this->members->count(),
            'unread_count' => $this->unreadCounts[$this->id] ?? 0,
            'last_message' => $this->when($lastMessage !== null, fn () => $lastMessage ? [
                'body' => \Str::limit($lastMessage->body, 80),
                'is_announcement' => $lastMessage->is_announcement,
                'is_complaint' => $lastMessage->is_complaint ?? false,
                'complaint_category' => $lastMessage->complaint_category,
                'sender_name' => $lastMessage->user?->name,
                'sent_at_formatted' => $lastMessage->created_at?->locale('id')->translatedFormat('d F Y, H:i'),
            ] : null),
        ];
    }
}

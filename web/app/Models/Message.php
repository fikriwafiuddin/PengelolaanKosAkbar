<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Pesan chat; is_announcement untuk pengumuman resmi admin.
 *
 * @property int $id
 * @property int $chat_room_id
 * @property int $user_id
 * @property string $body
 * @property bool $is_announcement
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['chat_room_id', 'user_id', 'body', 'is_announcement'])]
class Message extends Model
{
    /** @use HasFactory<\Database\Factories\MessageFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'is_announcement' => 'boolean',
        ];
    }

    /**
     * Grup chat tempat pesan dikirim.
     */
    public function chatRoom(): BelongsTo
    {
        return $this->belongsTo(ChatRoom::class);
    }

    /**
     * Pengirim pesan.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

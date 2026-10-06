<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Grup chat: pengumuman resmi & diskusi penghuni.
 *
 * @property int $id
 * @property string $name
 * @property string|null $description
 */
#[Fillable(['name', 'description'])]
class ChatRoom extends Model
{
    /** @use HasFactory<\Database\Factories\ChatRoomFactory> */
    use HasFactory;

    /**
     * Anggota grup chat.
     */
    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'chat_room_members')
            ->withPivot('joined_at')
            ->withTimestamps();
    }

    /**
     * Pesan-pesan di dalam grup chat.
     */
    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }
}

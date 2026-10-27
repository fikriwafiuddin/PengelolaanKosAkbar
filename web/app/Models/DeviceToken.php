<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Token FCM satu device milik pengguna (untuk push notification).
 *
 * @property int $id
 * @property int $user_id
 * @property string $token
 * @property string $platform
 * @property Carbon|null $last_used_at
 */
#[Fillable(['user_id', 'token', 'platform', 'last_used_at'])]
class DeviceToken extends Model
{
    /** @use HasFactory<\Database\Factories\DeviceTokenFactory> */
    use HasFactory;

    /**
     * Pemilik device.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

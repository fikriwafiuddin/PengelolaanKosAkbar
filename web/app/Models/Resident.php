<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Profil identitas penghuni (1:1 dengan akun users).
 *
 * @property int $id
 * @property int $user_id
 * @property string $full_name
 * @property string $identity_number
 * @property Carbon|null $birth_date
 * @property string|null $address
 * @property string|null $occupation
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['user_id', 'full_name', 'identity_number', 'birth_date', 'address', 'occupation'])]
class Resident extends Model
{
    /** @use HasFactory<\Database\Factories\ResidentFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'birth_date' => 'date',
        ];
    }

    /**
     * Akun user yang terhubung dengan profil ini.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Semua pemesanan kamar yang pernah dilakukan penghuni.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /**
     * Pemesanan aktif penghuni (kamar yang sedang disewa), jika ada.
     */
    public function activeBooking()
    {
        return $this->hasOne(Booking::class)->where('status', 'aktif')->latestOfMany('start_date');
    }
}

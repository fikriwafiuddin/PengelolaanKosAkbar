<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Data kamar kos beserta status ketersediaannya.
 *
 * @property int $id
 * @property string $room_number
 * @property string $type
 * @property float $price_monthly
 * @property string $status kosong|terisi|terbooking
 * @property string|null $description
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['room_number', 'type', 'price_monthly', 'status', 'description'])]
class Room extends Model
{
    /** @use HasFactory<\Database\Factories\RoomFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'price_monthly' => 'decimal:2',
        ];
    }

    /**
     * Fasilitas yang dimiliki kamar (many-to-many via room_facility).
     */
    public function facilities(): BelongsToMany
    {
        return $this->belongsToMany(Facility::class, 'room_facility');
    }

    /**
     * Semua riwayat pemesanan untuk kamar ini.
     */
    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    /**
     * Pemesanan aktif untuk kamar ini, jika sedang terisi.
     */
    public function activeBooking()
    {
        return $this->hasOne(Booking::class)->where('status', 'aktif')->latestOfMany('start_date');
    }

    /**
     * Label status dalam bahasa Indonesia untuk ditampilkan di UI.
     */
    public function statusLabel(): string
    {
        return match ($this->status) {
            'kosong' => 'Tersedia',
            'terisi' => 'Terisi',
            'terbooking' => 'Terbooking',
            default => $this->status,
        };
    }
}

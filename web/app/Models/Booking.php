<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Pemesanan kamar: tanggal mulai + durasi sewa.
 *
 * @property int $id
 * @property int $resident_id
 * @property int $room_id
 * @property Carbon $start_date
 * @property int $duration_months
 * @property string $status menunggu|aktif|selesai|batal
 * @property string|null $note
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['resident_id', 'room_id', 'start_date', 'duration_months', 'status', 'note'])]
class Booking extends Model
{
    /** @use HasFactory<\Database\Factories\BookingFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
        ];
    }

    /**
     * Penghuni yang melakukan pemesanan.
     */
    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }

    /**
     * Kamar yang dipesan.
     */
    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    /**
     * Tagihan sewa bulanan yang dihasilkan dari pemesanan ini.
     */
    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }
}

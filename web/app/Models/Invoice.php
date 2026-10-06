<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Tagihan sewa bulanan per periode (YYYY-MM).
 *
 * @property int $id
 * @property int $booking_id
 * @property string $period
 * @property float $amount
 * @property Carbon $due_date
 * @property string $status belum_bayar|lunas
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['booking_id', 'period', 'amount', 'due_date', 'status'])]
class Invoice extends Model
{
    /** @use HasFactory<\Database\Factories\InvoiceFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'amount' => 'decimal:2',
        ];
    }

    /**
     * Pemesanan pemilik tagihan ini.
     */
    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    /**
     * Pembayaran-pembayaran untuk tagihan ini.
     */
    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}

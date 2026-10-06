<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Pembayaran sewa + bukti transfer; diverifikasi admin.
 *
 * @property int $id
 * @property int $invoice_id
 * @property int $user_id
 * @property float $amount
 * @property string $method transfer|tunai
 * @property string|null $proof_path
 * @property string|null $receipt_no
 * @property string $status pending|terverifikasi|ditolak
 * @property int|null $verified_by
 * @property Carbon|null $paid_at
 * @property Carbon|null $verified_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['invoice_id', 'user_id', 'amount', 'method', 'proof_path', 'receipt_no', 'status', 'verified_by', 'paid_at', 'verified_at'])]
class Payment extends Model
{
    /** @use HasFactory<\Database\Factories\PaymentFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'paid_at' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }

    /**
     * Tagihan yang dibayar.
     */
    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    /**
     * User (penghuni) yang melakukan pembayaran.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Admin yang memverifikasi pembayaran.
     */
    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}

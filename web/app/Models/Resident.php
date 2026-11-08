<?php

namespace App\Models;

use App\Services\PiiEncryptionService;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

/**
 * Profil identitas penghuni (1:1 dengan akun users).
 *
 * Kolom data pribadi (identity_number, address, guardian_name,
 * guardian_phone) dapat menyimpan teks tersandi PII1: dari aplikasi
 * mobile — accessor di bawah menDEKRIPSI-nya secara otomatis saat
 * nilai DITAMPILKAN (profil mobile & dashboard web) memakai kunci
 * privat di .env. Nilai lama yang belum terenkripsi dilewatkan apa
 * adanya.
 *
 * @property int $id
 * @property int $user_id
 * @property string $full_name
 * @property string $identity_number
 * @property Carbon|null $birth_date
 * @property string|null $address
 * @property string|null $occupation
 * @property string|null $guardian_name
 * @property string|null $guardian_phone
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['user_id', 'full_name', 'identity_number', 'birth_date', 'address', 'occupation', 'guardian_name', 'guardian_phone'])]
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
     * NIK — didekripsi saat dibaca (bila tersimpan terenkripsi).
     */
    protected function identityNumber(): Attribute
    {
        return Attribute::get(
            fn ($value) => PiiEncryptionService::readable($value),
        );
    }

    /**
     * Alamat — didekripsi saat dibaca (bila tersimpan terenkripsi).
     */
    protected function address(): Attribute
    {
        return Attribute::get(
            fn ($value) => PiiEncryptionService::readable($value),
        );
    }

    /**
     * Nama penanggung jawab — didekripsi saat dibaca.
     */
    protected function guardianName(): Attribute
    {
        return Attribute::get(
            fn ($value) => PiiEncryptionService::readable($value),
        );
    }

    /**
     * No. HP penanggung jawab — didekripsi saat dibaca.
     */
    protected function guardianPhone(): Attribute
    {
        return Attribute::get(
            fn ($value) => PiiEncryptionService::readable($value),
        );
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

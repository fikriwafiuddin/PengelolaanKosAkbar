<?php

namespace App\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;

/**
 * Enkripsi data pribadi (PII) — sisi backend.
 *
 * Skema: aplikasi mobile mengenkripsi field sensitif dengan kunci
 * publik RSA (hibrida: RSA-OAEP membungkus kunci sesi AES-256-GCM),
 * lalu mengirim teks tersandi berformat:
 *
 *     PII1:<base64(RSA-OAEP(kunci32+nonce12))>.<base64(ct||tag)>
 *
 * Backend (satu-satunya pemegang kunci privat di .env):
 * - middleware menDEKRIPSI field berformat PII1 SEBELUM validasi,
 *   sehingga aturan validasi asli (mis. NIK 16 digit) tetap jalan;
 * - service menyimpan teks tersandi asli ke database (data at-rest
 *   terenkripsi);
 * - accessor model menDEKRIPSI saat data DITAMPILKAN ke pengguna
 *   (profil mobile & dashboard admin web).
 *
 * Semua metode statis dan aman dipanggil kapan pun: nilai lama yang
 * belum terenkripsi (data seeder / API non-mobile) dilewatkan apa
 * adanya.
 */
class PiiEncryptionService
{
    /**
     * Prefix penanda nilai terenkripsi.
     */
    public const MARKER = 'PII1:';

    /**
     * Kunci & IV untuk data legacy hasil percobaan enkripsi lama di APK (AES-128-CBC).
     */
    private const LEGACY_AES_KEY = 'Qwertyui87651234';
    private const LEGACY_AES_IV  = '1234567890123456';

    /**
     * Field yang dienkripsi aplikasi mobile (nama sama di request
     * maupun kolom database).
     */
    public const FIELDS = [
        'phone',
        'identity_number',
        'address',
        'guardian_name',
        'guardian_phone',
    ];

    /**
     * Enkripsi satu nilai teks biasa ke format PII1 memakai kunci publik RSA.
     */
    public static function encrypt(string $plain): ?string
    {
        $base64 = Config::get('encryption.public_key');

        if (! $base64) {
            return null;
        }

        $pem = base64_decode((string) $base64, true);

        if ($pem === false) {
            return null;
        }

        $publicKey = openssl_pkey_get_public($pem);

        if (! $publicKey) {
            return null;
        }

        try {
            $aesKey = random_bytes(32);
            $nonce = random_bytes(12);
            $tag = '';
            $ciphertext = openssl_encrypt($plain, 'aes-256-gcm', $aesKey, OPENSSL_RAW_DATA, $nonce, $tag);

            if ($ciphertext === false) {
                return null;
            }

            $payload = $ciphertext . $tag;
            $keymat = $aesKey . $nonce;

            if (! openssl_public_encrypt($keymat, $envelope, $publicKey, OPENSSL_PKCS1_OAEP_PADDING)) {
                return null;
            }

            return self::MARKER . base64_encode($envelope) . '.' . base64_encode($payload);
        } catch (\Throwable) {
            return null;
        }
    }

    /**
     * Coba dekripsi teks lama (kompatibilitas percobaan sebelumnya):
     * 1. Laravel Crypt (format JSON base64 eyJ...)
     * 2. AES-128-CBC mobile lama (kunci 'Qwertyui87651234', IV '1234567890123456')
     */
    public static function decryptLegacy(?string $value): ?string
    {
        if (! is_string($value) || $value === '') {
            return null;
        }

        // 1. Cek format Laravel Crypt (eyJ...)
        if (str_starts_with($value, 'eyJ')) {
            try {
                return \Illuminate\Support\Facades\Crypt::decryptString($value);
            } catch (\Throwable) {
                // Abaikan jika bukan format Crypt valid
            }
        }

        // 2. Cek format AES-128-CBC mobile lama (base64 tanpa spasi kelipatan 16 byte)
        if (strlen($value) >= 24 && preg_match('/^[A-Za-z0-9+\/]+={0,2}$/', $value)) {
            try {
                $raw = base64_decode($value, true);
                if ($raw !== false && strlen($raw) % 16 === 0) {
                    $plain = openssl_decrypt(
                        $raw,
                        'aes-128-cbc',
                        self::LEGACY_AES_KEY,
                        OPENSSL_RAW_DATA,
                        self::LEGACY_AES_IV
                    );
                    if ($plain !== false && preg_match('/^[\x20-\x7E]+$/', $plain)) {
                        return $plain;
                    }
                }
            } catch (\Throwable) {
                // Abaikan
            }
        }

        return null;
    }

    /**
     * Apakah kunci privat terpasang (fitur enkripsi aktif).
     */
    public static function enabled(): bool
    {
        return self::privateKey() !== null;
    }

    /**
     * Kunci privat PEM (dari .env) atau null.
     */
    private static function privateKey(): ?string
    {
        $base64 = Config::get('encryption.private_key');

        if (! $base64) {
            return null;
        }

        $pem = base64_decode((string) $base64, true);

        return $pem === false || ! str_contains($pem, 'PRIVATE KEY') ? null : $pem;
    }

    /**
     * Kunci publik DER SPKI ter-base64 — dibagikan ke aplikasi
     * mobile lewat GET /api/v1/auth/public-key.
     */
    public static function publicKeyDer(): ?string
    {
        $base64 = Config::get('encryption.public_key');

        if (! $base64) {
            return null;
        }

        $pem = base64_decode((string) $base64, true);

        if ($pem === false || ! str_contains($pem, 'PUBLIC KEY')) {
            return null;
        }

        // Ambil body PEM (tanpa header/footer) = base64 DER.
        $body = collect(explode("\n", $pem))
            ->filter(fn (string $line) => ! str_contains($line, 'KEY-----') && trim($line) !== '')
            ->implode('');

        return $body;
    }

    /**
     * Apakah nilai ini teks tersandi hasil aplikasi mobile.
     */
    public static function isEncrypted(mixed $value): bool
    {
        return is_string($value) && str_starts_with($value, self::MARKER);
    }

    /**
     * Dekripsi satu nilai; mengembalikan null bila bukan teks
     * tersandi atau gagal didekripsi.
     */
    public static function decrypt(?string $value): ?string
    {
        if (! self::isEncrypted($value)) {
            return null;
        }

        $privateKey = openssl_pkey_get_private(self::privateKey());

        if (! $privateKey) {
            return null;
        }

        $parts = explode('.', substr($value, strlen(self::MARKER)), 2);

        if (count($parts) !== 2) {
            return null;
        }

        $envelope = base64_decode($parts[0], true);
        $payload = base64_decode($parts[1], true);

        if ($envelope === false || $payload === false || strlen($payload) < 16) {
            return null;
        }

        // Buka amplop: kunci AES (32 byte) + nonce GCM (12 byte).
        if (! openssl_private_decrypt($envelope, $keymat, $privateKey, OPENSSL_PKCS1_OAEP_PADDING)) {
            return null;
        }

        if (strlen($keymat) !== 44) {
            return null;
        }

        $key = substr($keymat, 0, 32);
        $nonce = substr($keymat, 32, 12);
        $tag = substr($payload, -16);
        $ciphertext = substr($payload, 0, -16);

        $plain = openssl_decrypt($ciphertext, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $nonce, $tag);

        return $plain === false ? null : $plain;
    }

    /**
     * Nilai siap-tampil: terenkripsi -> didekripsi; selain itu
     * dikembalikan apa adanya (data lama / non-mobile).
     */
    public static function readable(mixed $value): mixed
    {
        if (! is_string($value) || $value === '') {
            return $value;
        }

        if (self::isEncrypted($value)) {
            return self::decrypt($value) ?? '[terenkripsi — kunci tidak cocok]';
        }

        // Coba dekripsi format legacy (Laravel Crypt atau APK lama AES-128-CBC)
        $legacy = self::decryptLegacy($value);
        if ($legacy !== null) {
            return $legacy;
        }

        return $value;
    }

    /**
     * Dekripsi field PII pada request JSON (SEBELUM validasi) dan
     * simpan teks tersandi aslinya di attributes untuk disimpan
     * service ke database.
     */
    public static function decryptRequest(Request $request): void
    {
        if (! $request->isJson()) {
            return;
        }

        $data = $request->json()->all();
        $ciphertext = [];

        foreach (self::FIELDS as $field) {
            $value = $data[$field] ?? null;

            if (self::isEncrypted($value)) {
                $plain = self::decrypt($value);

                // Gagal didekripsi: biarkan apa adanya supaya aturan
                // validasi asli yang menolaknya dengan pesan Indonesia.
                if ($plain !== null) {
                    $data[$field] = $plain;
                    $ciphertext[$field] = $value;
                }
            } elseif (is_string($value) && ($legacy = self::decryptLegacy($value)) !== null) {
                // Kompatibilitas jika client masih mengirim format legacy
                $data[$field] = $legacy;
                // Re-enkripsi ke format PII1 standar sebelum disimpan
                $ciphertext[$field] = self::encrypt($legacy) ?? $value;
            }
        }

        if ($ciphertext !== []) {
            $request->merge($data);
            $request->attributes->set('pii_ciphertext', $ciphertext);
        }
    }

    /**
     * Gabungkan teks tersandi stashed middleware ke data yang akan
     * disimpan — hanya untuk field yang memang datang terenkripsi.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public static function mergeCiphertext(Request $request, array $data): array
    {
        $ciphertext = $request->attributes->get('pii_ciphertext', []);

        foreach ($ciphertext as $field => $value) {
            if (array_key_exists($field, $data)) {
                $data[$field] = $value;
            }
        }

        return $data;
    }
}

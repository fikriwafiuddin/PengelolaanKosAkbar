<?php

/*
|--------------------------------------------------------------------------
| Konfigurasi Enkripsi Data Pribadi (PII)
|--------------------------------------------------------------------------
| Pasangan kunci RSA untuk fitur enkripsi field data pribadi
| (NIK, no. HP, alamat, penanggung jawab):
|
| - Aplikasi mobile mengENKRIPSI memakai kunci PUBLIK (diambil dari
|   endpoint /api/v1/auth/public-key).
| - Backend menDEKRIPSI memakai kunci PRIVAT di bawah ini (dari
|   .env) saat data ditampilkan ke pengguna.
|
| Nilai env = base64 dari PEM (satu baris, aman untuk file .env).
| Generate: php artisan encryption:generate
|
*/

return [
    'private_key' => env('ENCRYPTION_PRIVATE_KEY'),
    'public_key' => env('ENCRYPTION_PUBLIC_KEY'),
];

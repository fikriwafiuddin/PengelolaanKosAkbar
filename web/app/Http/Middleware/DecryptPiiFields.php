<?php

namespace App\Http\Middleware;

use App\Services\PiiEncryptionService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Dekripsi field data pribadi (PII) terenkripsi dari aplikasi mobile
 * SEBELUM validasi berjalan — sehingga aturan validasi asli (NIK 16
 * digit, dst.) tetap memeriksa nilai aslinya. Teks tersandi asli
 * disimpan di request attributes lalu dipakai service untuk
 * disimpan ke database (data at-rest tetap terenkripsi).
 */
class DecryptPiiFields
{
    public function handle(Request $request, Closure $next): Response
    {
        PiiEncryptionService::decryptRequest($request);

        return $next($request);
    }
}

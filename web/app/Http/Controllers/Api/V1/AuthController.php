<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\ProfileUpdateRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use App\Services\PiiEncryptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Autentikasi aplikasi mobile: registrasi, login, logout, profil,
 * dan pembaruan profil. Controller tipis — logika ada di AuthService.
 */
class AuthController extends Controller
{
    public function __construct(private readonly AuthService $auth)
    {}

    /**
     * GET /api/v1/auth/public-key — kunci publik RSA untuk fitur
     * enkripsi data pribadi di aplikasi mobile (SPKI DER base64).
     */
    public function publicKey(): JsonResponse
    {
        $key = PiiEncryptionService::publicKeyDer();

        abort_if($key === null, 503, 'Kunci enkripsi belum dikonfigurasi di server.');

        return response()->json([
            'data' => [
                'public_key' => $key,
                // Field yang wajib dienkripsi aplikasi mobile.
                'fields' => PiiEncryptionService::FIELDS,
                'format' => 'PII1:<base64(RSA-OAEP-SHA1(aes_key+nonce))>.<base64(AES-256-GCM ct+tag)>',
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/register — registrasi calon penghuni.
     *
     * Akun berstatus menunggu_validasi dan belum dapat login
     * sampai disetujui admin (tidak ada token yang diterbitkan).
     *
     * Field PII yang datang terenkripsi (PII1:) sudah didekripsi
     * middleware pii.decrypt untuk validasi; teks tersandi aslinya
     * digabung kembali di sini agar database menyimpan bentuk
     * terenkripsi.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = $this->auth->register(
            PiiEncryptionService::mergeCiphertext($request, $request->validated()),
        );

        return response()->json([
            'message' => 'Registrasi berhasil. Akun Anda menunggu validasi admin sebelum dapat digunakan untuk login.',
            'data' => [
                'user' => new UserResource($user),
            ],
        ], 201);
    }

    /**
     * POST /api/v1/auth/login — login penghuni/admin mobile.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->auth->login(
            $request->validated('email'),
            $request->validated('password'),
        );

        return response()->json([
            'message' => 'Login berhasil.',
            'data' => [
                'user' => new UserResource($result['user']),
                'token' => $result['token'],
            ],
        ]);
    }

    /**
     * POST /api/v1/auth/logout — cabut token device ini.
     */
    public function logout(Request $request): JsonResponse
    {
        $this->auth->logout($request->user());

        return response()->json(['message' => 'Logout berhasil.']);
    }

    /**
     * GET /api/v1/auth/me — profil user yang sedang login.
     */
    public function me(Request $request): JsonResponse
    {
        $user = $this->auth->profile($request->user());

        return response()->json(['data' => new UserResource($user)]);
    }

    /**
     * PUT /api/v1/auth/profile — perbarui profil penghuni.
     *
     * Sama seperti register: field PII tervalidasi dalam bentuk
     * terdekripsi, disimpan dalam bentuk terenkripsi.
     */
    public function updateProfile(ProfileUpdateRequest $request): JsonResponse
    {
        $user = $this->auth->updateProfile(
            $request->user(),
            PiiEncryptionService::mergeCiphertext($request, $request->validated()),
        );

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'data' => new UserResource($user),
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Autentikasi aplikasi mobile: registrasi, login, logout, profil.
 * Controller tipis — logika ada di AuthService.
 */
class AuthController extends Controller
{
    public function __construct(private readonly AuthService $auth)
    {}

    /**
     * POST /api/v1/auth/register — registrasi calon penghuni.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->auth->register($request->validated());

        return response()->json([
            'message' => 'Registrasi berhasil. Silakan masuk dengan akun Anda.',
            'data' => [
                'user' => new UserResource($result['user']),
                'token' => $result['token'],
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
}

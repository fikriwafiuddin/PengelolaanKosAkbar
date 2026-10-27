<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Registrasi token FCM device penghuni (aplikasi mobile) agar
 * server dapat mengirim push notification.
 */
class DeviceTokenController extends Controller
{
    /**
     * POST /api/v1/devices — daftarkan / perbarui token device.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'max:20'],
        ], [
            'token.required' => 'Token device wajib dikirim.',
            'token.max' => 'Token device tidak valid.',
        ]);

        DeviceToken::query()->updateOrCreate(
            ['token' => $data['token']],
            [
                'user_id' => $request->user()->id,
                'platform' => $data['platform'] ?? 'android',
                'last_used_at' => now(),
            ],
        );

        return response()->json([
            'message' => 'Token device terdaftar.',
            'data' => ['registered' => true],
        ]);
    }

    /**
     * DELETE /api/v1/devices — hapus token device (dipanggil saat
     * logout agar device tidak menerima push lagi).
     */
    public function destroy(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string', 'max:255'],
        ], [
            'token.required' => 'Token device wajib dikirim.',
        ]);

        DeviceToken::query()
            ->where('token', $data['token'])
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json([
            'message' => 'Token device dihapus.',
            'data' => ['removed' => true],
        ]);
    }
}

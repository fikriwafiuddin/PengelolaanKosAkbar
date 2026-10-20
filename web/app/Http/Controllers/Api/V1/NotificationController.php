<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Notifikasi milik penghuni (pengingat pembayaran, dst.) — dibaca
 * aplikasi mobile.
 */
class NotificationController extends Controller
{
    /**
     * GET /api/v1/notifications — daftar notifikasi terbaru (belum
     * dibaca duluan) + jumlah belum dibaca.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $notifications = $user->notifications()
            ->latest()
            ->limit(30)
            ->get()
            ->map(fn ($notification) => [
                'id' => $notification->id,
                'title' => $notification->data['title'] ?? null,
                'body' => $notification->data['body'] ?? null,
                'invoice_id' => $notification->data['invoice_id'] ?? null,
                'room_number' => $notification->data['room_number'] ?? null,
                'read_at' => $notification->read_at?->toIso8601String(),
                'created_at' => $notification->created_at?->toIso8601String(),
            ]);

        return response()->json([
            'data' => $notifications,
            'unread_count' => $user->unreadNotifications()->count(),
        ]);
    }

    /**
     * POST /api/v1/notifications/mark-read — tandai semua notifikasi
     * sudah dibaca.
     */
    public function markRead(Request $request): JsonResponse
    {
        $marked = $request->user()->unreadNotifications()->update(['read_at' => now()]);

        return response()->json([
            'data' => ['marked' => $marked],
        ]);
    }
}

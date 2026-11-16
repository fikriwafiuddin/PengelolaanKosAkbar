<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Chat\StoreMessageRequest;
use App\Http\Resources\ChatRoomResource;
use App\Http\Resources\MessageResource;
use App\Models\ChatRoom;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * Chat grup penghuni & pengelola (aplikasi mobile). Controller tipis —
 * logika ada di ChatService.
 */
class ChatController extends Controller
{
    public function __construct(private readonly ChatService $chat)
    {}

    /**
     * GET /api/v1/chat/rooms — daftar grup milik pengguna + jumlah
     * pesan belum dibaca per grup.
     */
    public function rooms(Request $request): JsonResponse
    {
        $user = $request->user();
        $rooms = $this->chat->roomsForUser($user);
        $unread = $this->chat->unreadCounts($user);

        return response()->json([
            'data' => $rooms
                ->map(fn (ChatRoom $room) => (new ChatRoomResource($room, $unread))->resolve())
                ->values(),
            'unread_total' => array_sum($unread),
        ]);
    }

    /**
     * GET /api/v1/chat/rooms/{room}/messages?after_id=&mark_read=
     * Riwayat pesan (terbaru di akhir); after_id untuk polling ringan.
     */
    public function messages(Request $request, ChatRoom $room): AnonymousResourceCollection
    {
        $room = $this->chat->findRoomForUser($request->user(), $room);

        $messages = $this->chat->messages(
            $room,
            $request->user(),
            $request->integer('after_id') ?: null,
            $request->boolean('mark_read', true),
        );

        return MessageResource::collection($messages);
    }

    /**
     * GET /api/v1/chat/complaint-room — ambil / buat saluran laporan & keluhan
     * khusus milik penghuni yang sedang login.
     */
    public function complaintRoom(Request $request): JsonResponse
    {
        $room = $this->chat->ensureComplaintRoom($request->user());
        $unread = $this->chat->unreadCounts($request->user());

        return response()->json([
            'data' => (new ChatRoomResource($room, $unread))->resolve(),
        ]);
    }

    /**
     * POST /api/v1/chat/rooms/{room}/messages — kirim pesan;
     * admin dapat menandai is_announcement untuk pengumuman resmi,
     * penghuni dapat mengirim laporan/keluhan (is_complaint & complaint_category).
     */
    public function store(StoreMessageRequest $request, ChatRoom $room): JsonResponse
    {
        $room = $this->chat->findRoomForUser($request->user(), $room);

        $message = $this->chat->sendMessage(
            $room,
            $request->user(),
            $request->validated('body'),
            $request->boolean('is_announcement'),
            $request->boolean('is_complaint'),
            $request->validated('complaint_category'),
        );

        return (new MessageResource($message))
            ->response()
            ->setStatusCode(201);
    }
}

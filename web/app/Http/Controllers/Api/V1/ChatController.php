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
     * POST /api/v1/chat/rooms/{room}/messages — kirim pesan;
     * admin dapat menandai is_announcement untuk pengumuman resmi.
     */
    public function store(StoreMessageRequest $request, ChatRoom $room): JsonResponse
    {
        $room = $this->chat->findRoomForUser($request->user(), $room);

        $message = $this->chat->sendMessage(
            $room,
            $request->user(),
            $request->validated('body'),
            $request->boolean('is_announcement'),
        );

        return (new MessageResource($message))
            ->response()
            ->setStatusCode(201);
    }
}

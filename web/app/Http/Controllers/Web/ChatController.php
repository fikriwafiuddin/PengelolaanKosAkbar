<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Http\Requests\Chat\StoreChatRoomRequest;
use App\Http\Requests\Chat\StoreMessageRequest;
use App\Http\Resources\ChatRoomResource;
use App\Http\Resources\MessageResource;
use App\Models\ChatRoom;
use App\Models\User;
use App\Services\ChatService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Chat & Pengumuman di dashboard admin: pantau grup, kirim pesan atau
 * pengumuman resmi, buat grup baru. Controller tipis — logika di
 * ChatService.
 */
class ChatController extends Controller
{
    public function __construct(private readonly ChatService $chat)
    {}

    /**
     * GET /chat?room={id} — halaman Chat & Pengumuman.
     */
    public function index(Request $request): Response
    {
        $user = $request->user();
        $rooms = $this->chat->roomsForUser($user);

        $activeRoom = $rooms->firstWhere('id', (int) $request->query('room'))
            ?? $rooms->first();

        return Inertia::render('chat/index', [
            'rooms' => $rooms
                ->map(fn (ChatRoom $room) => (new ChatRoomResource($room))->resolve())
                ->values(),
            'activeRoom' => $activeRoom ? (new ChatRoomResource($activeRoom))->resolve() : null,
            'messages' => $activeRoom
                ? MessageResource::collection(
                    $this->chat->messages($activeRoom, $user, markRead: true),
                )->resolve()
                : [],
            // Calon anggota untuk dialog buat grup: penghuni aktif.
            'residents' => User::query()
                ->where('role', 'penghuni')
                ->where('status', 'aktif')
                ->orderBy('name')
                ->get(['id', 'name'])
                ->map(fn (User $resident) => ['id' => $resident->id, 'name' => $resident->name])
                ->all(),
        ]);
    }

    /**
     * POST /chat/rooms — buat grup chat baru beserta anggota awal.
     */
    public function storeRoom(StoreChatRoomRequest $request): RedirectResponse
    {
        $room = $this->chat->createRoom(
            $request->user(),
            $request->validated('name'),
            $request->validated('description'),
            $request->validated('member_ids', []),
        );

        return redirect()
            ->route('chat.index', ['room' => $room->id])
            ->with('success', 'Grup chat "'.$room->name.'" berhasil dibuat.');
    }

    /**
     * POST /chat/rooms/{room}/messages — kirim pesan / pengumuman.
     */
    public function storeMessage(StoreMessageRequest $request, ChatRoom $room): RedirectResponse
    {
        $room = $this->chat->findRoomForUser($request->user(), $room);

        $this->chat->sendMessage(
            $room,
            $request->user(),
            $request->validated('body'),
            $request->boolean('is_announcement'),
        );

        return back()->with('success', $request->boolean('is_announcement')
            ? 'Pengumuman terkirim ke '.$room->name.'.'
            : 'Pesan terkirim.');
    }
}

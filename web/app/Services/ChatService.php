<?php

namespace App\Services;

use App\Models\ChatRoom;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Logika bisnis chat grup & pengumuman: keanggotaan, daftar grup,
 * pengiriman pesan (penghuni) dan pengumuman resmi (admin), serta
 * penanda baca untuk badge belum-dibaca.
 */
class ChatService
{
    /**
     * Nama grup baku — grup utama seluruh penghuni & pengelola.
     */
    public const DEFAULT_ROOM_NAME = 'Umum — Kost Akbar';

    /**
     * Daftar grup chat milik pengguna:
     * - penghuni: semua grup tempatnya menjadi anggota (otomatis
     *   bergabung ke grup Umum saat pertama kali membuka chat);
     * - admin: semua grup (pengelola bisa memantau & menyiarkan
     *   pengumuman ke grup mana pun).
     *
     * @return Collection<int, ChatRoom>
     */
    public function roomsForUser(User $user): Collection
    {
        if ($user->isAdmin()) {
            return ChatRoom::query()
                ->withCount('members')
                ->with(['messages' => fn ($query) => $query->latest('id')->limit(1)])
                ->orderBy('name')
                ->get();
        }

        $this->ensureDefaultMembership($user);

        return ChatRoom::query()
            ->whereHas('members', fn (Builder $query) => $query->where('user_id', $user->id))
            ->withCount('members')
            ->with(['messages' => fn ($query) => $query->latest('id')->limit(1)])
            ->orderBy('name')
            ->get();
    }

    /**
     * Cari satu grup; 404 bila penghuni bukan anggota (admin bebas).
     */
    public function findRoomForUser(User $user, ChatRoom $room): ChatRoom
    {
        if (! $user->isAdmin()) {
            $isMember = $room->members()
                ->where('user_id', $user->id)
                ->exists();

            abort_unless($isMember, 404, 'Grup chat tidak ditemukan.');
        }

        return $room->loadCount('members');
    }

    /**
     * Pesan dalam satu grup (terbaru di akhir) + tandai sudah dibaca.
     *
     * Opsi:
     * - after_id: hanya pesan setelah id tertentu (polling ringan)
     * - mark_read (default true): perbarui penanda baca anggota
     */
    public function messages(ChatRoom $room, User $user, ?int $afterId = null, bool $markRead = true): Collection
    {
        $messages = $room->messages()
            ->with('user:id,name,role')
            ->when($afterId, fn (Builder $query, int $id) => $query->where('id', '>', $id))
            ->orderBy('id')
            ->limit(200)
            ->get();

        // Penanda baca hanya bergeser maju (pesan lama di-atas sudah
        // pernah dibaca tidak menggeser penanda mundur).
        if ($markRead && $messages->isNotEmpty()) {
            $latestId = (int) $messages->max('id');

            DB::table('chat_room_members')
                ->where('chat_room_id', $room->id)
                ->where('user_id', $user->id)
                ->where(fn ($query) => $query
                    ->whereNull('last_read_message_id')
                    ->orWhere('last_read_message_id', '<', $latestId))
                ->update(['last_read_message_id' => $latestId]);
        }

        return $messages;
    }

    /**
     * Jumlah pesan belum dibaca per grup untuk satu pengguna
     * (pesan setelah penanda baca terakhir).
     *
     * @return array<int, int> map chat_room_id => jumlah
     */
    public function unreadCounts(User $user): array
    {
        if ($user->isAdmin()) {
            return [];
        }

        $this->ensureDefaultMembership($user);

        $memberships = DB::table('chat_room_members')
            ->where('user_id', $user->id)
            ->get(['chat_room_id', 'last_read_message_id']);

        return $memberships
            ->mapWithKeys(fn ($membership) => [
                $membership->chat_room_id => Message::query()
                    ->where('chat_room_id', $membership->chat_room_id)
                    ->when(
                        $membership->last_read_message_id,
                        fn (Builder $query, int $lastRead) => $query->where('id', '>', $lastRead),
                    )
                    ->count(),
            ])
            ->all();
    }

    /**
     * Kirim pesan ke grup. Hanya admin yang boleh menandai pesan
     * sebagai pengumuman resmi.
     */
    public function sendMessage(ChatRoom $room, User $sender, string $body, bool $isAnnouncement = false): Message
    {
        if ($isAnnouncement && ! $sender->isAdmin()) {
            throw ValidationException::withMessages([
                'is_announcement' => 'Hanya pengelola yang dapat mengirim pengumuman resmi.',
            ]);
        }

        if (! $sender->isAdmin()) {
            $isMember = $room->members()->where('user_id', $sender->id)->exists();

            abort_unless($isMember, 404, 'Grup chat tidak ditemukan.');
        }

        $message = $room->messages()->create([
            'user_id' => $sender->id,
            'body' => $body,
            'is_announcement' => $isAnnouncement,
        ]);

        // Pesan sendiri langsung terhitung sudah dibaca.
        $this->markReadUpTo($room, $sender, $message->id);

        return $message->load('user:id,name,role');
    }

    /**
     * Buat grup chat baru (admin) beserta anggota awalnya.
     *
     * @param  array<int, int>  $memberIds
     */
    public function createRoom(User $admin, string $name, ?string $description, array $memberIds): ChatRoom
    {
        $room = ChatRoom::query()->create([
            'name' => $name,
            'description' => $description,
        ]);

        // Admin pembuat selalu ikut menjadi anggota.
        $room->members()->attach(array_unique([
            $admin->id,
            ...$memberIds,
        ]));

        return $room->loadCount('members');
    }

    /**
     * Pastikan grup Umum ada dan penghuni terdaftar sebagai anggota
     * (dipanggil saat penghuni pertama kali membuka fitur chat).
     */
    private function ensureDefaultMembership(User $user): void
    {
        $room = ChatRoom::query()->firstOrCreate(
            ['name' => self::DEFAULT_ROOM_NAME],
            ['description' => 'Grup utama seluruh penghuni & pengelola Kost Akbar.'],
        );

        $room->members()->syncWithoutDetaching([$user->id]);
    }

    /**
     * Geser penanda baca anggota sampai pesan tertentu.
     */
    private function markReadUpTo(ChatRoom $room, User $user, int $messageId): void
    {
        DB::table('chat_room_members')
            ->where('chat_room_id', $room->id)
            ->where('user_id', $user->id)
            ->update(['last_read_message_id' => $messageId]);
    }
}

<?php

namespace Database\Seeders;

use App\Models\ChatRoom;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Grup chat demo (Sprint 3): grup Umum berisi seluruh pengguna aktif
 * + satu grup lantai, beserta contoh pengumuman & percakapan.
 */
class ChatRoomSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('role', 'admin')->first();
        $residents = User::query()
            ->where('role', 'penghuni')
            ->where('status', 'aktif')
            ->orderBy('id')
            ->get();

        // Grup utama: admin + semua penghuni aktif.
        $umum = ChatRoom::query()->updateOrCreate(
            ['name' => 'Umum — Kost Akbar'],
            ['description' => 'Grup utama seluruh penghuni & pengelola Kost Akbar.'],
        );
        $umum->members()->sync(
            collect([$admin->id, ...$residents->pluck('id')])->filter()->all(),
        );

        // Grup lantai 1 (contoh grup khusus).
        $lantai1 = ChatRoom::query()->updateOrCreate(
            ['name' => 'Lantai 1 — AC'],
            ['description' => 'Diskusi penghuni lantai 1 (kamar 1-9).'],
        );
        $lantai1->members()->sync(
            collect([$admin->id, ...$residents->take(5)->pluck('id')])->filter()->all(),
        );

        $this->seedConversations($umum, $admin, $residents);
        $this->seedConversations($lantai1, $admin, $residents, floorOnly: true);
    }

    /**
     * Contoh pengumuman admin + balasan penghuni.
     */
    private function seedConversations(ChatRoom $room, ?User $admin, $residents, bool $floorOnly = false): void
    {
        $start = now()->subDays(2)->setTime(8, 0);

        $conversation = $floorOnly ? [
            ['user' => $admin, 'body' => 'AC lantai 1 akan servis rutin hari Sabtu pukul 09.00. Mohon kamar dalam keadaan terbuka ya. Terima kasih.', 'announcement' => true, 'at' => $start],
            ['user' => $residents[1], 'body' => 'Baik bu, noted. Terima kasih infonya.', 'announcement' => false, 'at' => $start->copy()->addMinutes(12)],
            ['user' => $residents[2], 'body' => 'Siap, saya akan di kos saat itu.', 'announcement' => false, 'at' => $start->copy()->addMinutes(30)],
        ] : [
            ['user' => $admin, 'body' => 'Selamat datang di grup Kost Akbar! Grup ini dipakai untuk pengumuman resmi pengelola dan diskusi antar penghuni.', 'announcement' => true, 'at' => $start],
            ['user' => $admin, 'body' => 'Pengingat: pembayaran sewa bulanan jatuh tempo setiap tanggal 25. Silakan transfer & unggah bukti bayar lewat aplikasi.', 'announcement' => true, 'at' => $start->copy()->addMinutes(5)],
            ['user' => $residents[0], 'body' => 'Baik bu Ririn, terima kasih infonya.', 'announcement' => false, 'at' => $start->copy()->addMinutes(20)],
            ['user' => $residents[3], 'body' => 'Ibu, untuk tamu yang menginap apakah perlu lapor dulu?', 'announcement' => false, 'at' => $start->copy()->addHours(3)],
            ['user' => $admin, 'body' => 'Iya, mohon lapor maksimal H-1 supaya kami catat di buku tamu. Terima kasih.', 'announcement' => false, 'at' => $start->copy()->addHours(4)],
        ];

        foreach ($conversation as $message) {
            if (! $message['user']) {
                continue;
            }

            Message::query()->updateOrCreate(
                [
                    'chat_room_id' => $room->id,
                    'user_id' => $message['user']->id,
                    'body' => $message['body'],
                ],
                [
                    'is_announcement' => $message['announcement'],
                    'created_at' => $message['at'],
                    'updated_at' => $message['at'],
                ],
            );
        }

        // Penanda baca: semua anggota dianggap sudah membaca riwayat
        // lama kecuali penghuni pertama (agar badge belum-dibaca
        // terlihat di demo aplikasi mobile).
        $lastMessage = $room->messages()->latest('id')->first();

        if ($lastMessage) {
            $room->members()->newPivotStatement()
                ->where('chat_room_id', $room->id)
                ->update(['last_read_message_id' => $lastMessage->id]);

            if (! $floorOnly && $residents->isNotEmpty()) {
                $room->members()->newPivotStatement()
                    ->where('chat_room_id', $room->id)
                    ->where('user_id', $residents[0]->id)
                    ->update(['last_read_message_id' => $room->messages()->orderBy('id')->value('id')]);
            }
        }
    }
}

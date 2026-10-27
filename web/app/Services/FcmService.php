<?php

namespace App\Services;

use App\Models\Message;
use App\Models\User;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Jembatan ke Firebase: Cloud Messaging (push notification) dan
 * Firestore (penyimpanan realtime chat) — dipakai server lewat
 * REST API HTTP v1 dengan service account, tanpa paket composer
 * tambahan.
 *
 * Semua metode AMAN dipanggil kapan pun: bila service account
 * belum dipasang (storage/app/firebase/service-account.json tidak
 * ada) atau Firebase gagal dihubungi, operasi jadi no-op dan alur
 * utama (notifikasi database + polling chat) tetap berjalan.
 */
class FcmService
{
    /**
     * Path service account relatif folder storage/app.
     */
    private const SERVICE_ACCOUNT_PATH = 'app/firebase/service-account.json';

    /**
     * Masa berlaku access token yang di-cache (token asli 1 jam).
     */
    private const TOKEN_TTL_SECONDS = 3000;

    /**
     * Skope OAuth untuk kirim FCM + tulis Firestore.
     */
    private const OAUTH_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/datastore';

    /**
     * Apakah Firebase aktif (service account terpasang).
     */
    public function enabled(): bool
    {
        return $this->credentials() !== null;
    }

    /**
     * Kirim push notification ke semua device milik satu user.
     *
     * @param  array<string, string>  $data  payload data tambahan (mis. type, chat_room_id)
     */
    public function sendToUser(User $user, string $title, string $body, array $data = []): void
    {
        $tokens = $user->deviceTokens()->pluck('token');

        foreach ($tokens as $token) {
            $this->sendToDevice($token, $title, $body, $data, $user);
        }
    }

    /**
     * Kirim push notification ke beberapa user sekaligus.
     *
     * @param  iterable<User>  $users
     */
    public function sendToUsers(iterable $users, string $title, string $body, array $data = []): void
    {
        foreach ($users as $user) {
            $this->sendToUser($user, $title, $body, $data);
        }
    }

    /**
     * Kirim satu pesan FCM (notification + data). Token yang sudah
     * tidak terdaftar dihapus otomatis dari daftar device.
     *
     * @param  array<string, string>  $data
     */
    public function sendToDevice(string $token, string $title, string $body, array $data = [], ?User $owner = null): void
    {
        if (! $this->enabled()) {
            return;
        }

        try {
            $response = Http::withToken($this->accessToken())
                ->timeout(10)
                ->post("{$this->fcmBase()}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => ['title' => $title, 'body' => $body],
                        'data' => array_map(fn ($value) => (string) $value, $data),
                        'android' => ['priority' => 'high'],
                    ],
                ]);

            // 404 / 400 UNREGISTERED -> device sudah hapus aplikasi.
            if ($response->status() === 404 || $response->status() === 400) {
                $owner?->deviceTokens()->where('token', $token)->delete();
            }
        } catch (\Throwable $e) {
            Log::warning('FCM gagal terkirim: '.$e->getMessage());
        }
    }

    /**
     * Tulis satu pesan chat ke Firestore (dual-write; MySQL tetap
     * sumber kebenaran) sehingga aplikasi mobile yang terhubung
     * menerima update realtime lewat stream.
     *
     * Struktur: chatRooms/{roomId}/messages/{messageId}
     */
    public function writeChatMessage(Message $message): void
    {
        if (! $this->enabled()) {
            return;
        }

        $document = [
            'fields' => [
                'id' => ['integerValue' => (string) $message->id],
                'chatRoomId' => ['integerValue' => (string) $message->chat_room_id],
                'body' => ['stringValue' => $message->body],
                'isAnnouncement' => ['booleanValue' => $message->is_announcement],
                'senderId' => ['integerValue' => (string) $message->user_id],
                'senderName' => ['stringValue' => $message->user?->name ?? ''],
                'senderRole' => ['stringValue' => $message->user?->role ?? ''],
                'sentAt' => ['timestampValue' => $message->created_at?->toIso8601String()],
            ],
        ];

        try {
            Http::withToken($this->accessToken())
                ->timeout(10)
                ->patch(
                    "{$this->firestoreBase()}/chatRooms/{$message->chat_room_id}/messages/{$message->id}",
                    $document,
                );
        } catch (\Throwable $e) {
            Log::warning('Firestore gagal ditulis: '.$e->getMessage());
        }
    }

    /**
     * Access token OAuth2 dari service account (JWT RS256 dibuat
     * manual dengan openssl — tanpa paket tambahan), di-cache.
     */
    private function accessToken(): ?string
    {
        if (! $this->enabled()) {
            return null;
        }

        return Cache::remember('firebase.access_token', self::TOKEN_TTL_SECONDS, function () {
            $credentials = $this->credentials();
            $issuedAt = time();

            $claims = [
                'iss' => $credentials['client_email'],
                'scope' => self::OAUTH_SCOPE,
                'aud' => $credentials['token_uri'],
                'iat' => $issuedAt,
                'exp' => $issuedAt + 3600,
            ];

            $base64Url = fn (string $raw) => rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');

            $header = $base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $payload = $base64Url(json_encode($claims));
            $signatureInput = "{$header}.{$payload}";

            openssl_sign(
                $signatureInput,
                $signature,
                $credentials['private_key'],
                OPENSSL_ALGO_SHA256,
            );

            $assertion = $signatureInput.'.'.$base64Url($signature);

            $response = Http::asForm()
                ->timeout(10)
                ->post($credentials['token_uri'], [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $assertion,
                ]);

            return $response->json('access_token');
        });
    }

    /**
     * Base URL FCM HTTP v1 untuk project ini.
     */
    private function fcmBase(): string
    {
        return 'https://fcm.googleapis.com/v1/projects/'.$this->credentials()['project_id'];
    }

    /**
     * Base URL Firestore REST untuk project ini.
     */
    private function firestoreBase(): string
    {
        return 'https://firestore.googleapis.com/v1/projects/'
            .$this->credentials()['project_id']
            .'/databases/(default)/documents';
    }

    /**
     * Baca & validasi service account (null bila belum dipasang).
     *
     * @return array<string, string>|null
     */
    private function credentials(): ?array
    {
        $path = storage_path(self::SERVICE_ACCOUNT_PATH);

        if (! is_file($path)) {
            return null;
        }

        $credentials = json_decode((string) file_get_contents($path), true);

        if (! is_array($credentials)
            || empty($credentials['project_id'])
            || empty($credentials['client_email'])
            || empty($credentials['private_key'])
            || empty($credentials['token_uri'])) {
            return null;
        }

        return $credentials;
    }
}

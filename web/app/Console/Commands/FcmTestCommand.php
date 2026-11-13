<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\FcmService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Diagnosa & uji kirim push notification FCM ke satu penghuni:
 *
 *   php artisan fcm:test tegarnugroho@kostakbar.id
 *
 * Menampilkan status lengkap (service account, token device) dan
 * respons MENTAH dari server FCM Google — termasuk pesan error
 * persisnya bila pengiriman gagal (token tidak terdaftar, kredensial
 * salah, dsb.) sehingga masalah mudah dikenali.
 */
class FcmTestCommand extends Command
{
    protected $signature = 'fcm:test {email} {--title=Uji Push Kost Akbar} {--body=Jika Anda membaca ini, push notification berfungsi.}';

    protected $description = 'Uji kirim push FCM ke semua device milik satu pengguna (tampilkan respons mentah)';

    public function handle(FcmService $fcm): int
    {
        $this->info('=== Status Firebase Cloud Messaging ===');
        $this->line('Service account : '.($fcm->enabled() ? 'AKTIF' : 'TIDAK ADA (storage/app/firebase/service-account.json)'));
        $this->line('Token device    : '.\App\Models\DeviceToken::count().' terdaftar');
        $this->newLine();

        if (! $fcm->enabled()) {
            $this->error('Service account belum dipasang — jalankan panduan docs/FIREBASE_SETUP.md bagian 5.');

            return self::FAILURE;
        }

        $user = User::query()->where('email', $this->argument('email'))->first();

        if (! $user) {
            $this->error("User {$this->argument('email')} tidak ditemukan.");

            return self::FAILURE;
        }

        $tokens = $user->deviceTokens()->pluck('token');

        if ($tokens->isEmpty()) {
            $this->warn("User {$user->email} belum punya token device.");
            $this->line('Artinya aplikasi mobile belum pernah berhasil mendaftarkan token');
            $this->line('(login ulang di aplikasi dengan Firebase aktif + backend hidup).');

            return self::FAILURE;
        }

        $reflection = new \ReflectionMethod($fcm, 'accessToken');
        $reflection->setAccessible(true);
        $accessToken = $reflection->invoke($fcm);
        $project = json_decode((string) file_get_contents(storage_path('app/firebase/service-account.json')), true)['project_id'];

        foreach ($tokens as $index => $token) {
            $this->line('['.($index + 1)."] kirim ke device: {$token}");

            $response = Http::withToken($accessToken)
                ->timeout(15)
                ->post("https://fcm.googleapis.com/v1/projects/{$project}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $this->option('title'),
                            'body' => $this->option('body'),
                        ],
                        'data' => ['type' => 'test'],
                        'android' => ['priority' => 'high'],
                    ],
                ]);

            if ($response->successful()) {
                $this->info('  BERHASIL — '.$response->json('name'));
            } else {
                $this->error('  GAGAL ['.$response->status().'] '.$response->body());
            }
        }

        return self::SUCCESS;
    }
}

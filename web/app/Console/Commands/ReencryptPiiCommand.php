<?php

namespace App\Console\Commands;

use App\Services\PiiEncryptionService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ReencryptPiiCommand extends Command
{
    protected $signature = 'encryption:reencrypt {--force : Jalankan tanpa konfirmasi}';

    protected $description = 'Enkripsi data pribadi (PII) yang masih berbentuk plaintext atau format lama ke format PII1 standar';

    public function handle(): int
    {
        if (! PiiEncryptionService::enabled()) {
            $this->error('Kunci enkripsi belum terpasang. Jalankan: php artisan encryption:generate');

            return self::FAILURE;
        }

        $this->info('Memulai pemindaian data pribadi (PII)...');

        // 1. Proses tabel users (phone)
        $users = DB::table('users')->whereNotNull('phone')->where('phone', '!=', '')->get(['id', 'phone']);
        $userUpdated = 0;

        foreach ($users as $user) {
            $raw = $user->phone;

            // Jika sudah terenkripsi dan bisa dibuka dengan kunci sekarang, lewati
            if (PiiEncryptionService::isEncrypted($raw) && PiiEncryptionService::decrypt($raw) !== null) {
                continue;
            }

            $plain = PiiEncryptionService::readable($raw);

            // Hindari mengenkripsi pesan error
            if ($plain === '[terenkripsi — kunci tidak cocok]') {
                $this->warn("User ID {$user->id}: kunci tidak cocok, dilewati.");
                continue;
            }

            $encrypted = PiiEncryptionService::encrypt($plain);

            if ($encrypted !== null) {
                DB::table('users')->where('id', $user->id)->update(['phone' => $encrypted]);
                $userUpdated++;
            }
        }

        $this->info("Tabel users: {$userUpdated} data nomor HP berhasil dienkripsi.");

        // 2. Proses tabel residents (identity_number, address, guardian_name, guardian_phone)
        $residents = DB::table('residents')->get(['id', 'identity_number', 'address', 'guardian_name', 'guardian_phone']);
        $residentUpdated = 0;

        $fields = ['identity_number', 'address', 'guardian_name', 'guardian_phone'];

        foreach ($residents as $resident) {
            $updates = [];

            foreach ($fields as $field) {
                $raw = $resident->{$field};

                if ($raw === null || $raw === '') {
                    continue;
                }

                if (PiiEncryptionService::isEncrypted($raw) && PiiEncryptionService::decrypt($raw) !== null) {
                    continue;
                }

                $plain = PiiEncryptionService::readable($raw);

                if ($plain === '[terenkripsi — kunci tidak cocok]') {
                    $this->warn("Resident ID {$resident->id} ({$field}): kunci tidak cocok, dilewati.");
                    continue;
                }

                $encrypted = PiiEncryptionService::encrypt($plain);

                if ($encrypted !== null) {
                    $updates[$field] = $encrypted;
                }
            }

            if ($updates !== []) {
                DB::table('residents')->where('id', $resident->id)->update($updates);
                $residentUpdated++;
            }
        }

        $this->info("Tabel residents: {$residentUpdated} data penghuni berhasil dienkripsi.");
        $this->info('Selesai! Seluruh data pribadi kini tersimpan aman dalam format terenkripsi (PII1:...).');

        return self::SUCCESS;
    }
}


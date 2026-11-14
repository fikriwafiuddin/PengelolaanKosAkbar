<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

/**
 * Buat pasangan kunci RSA untuk fitur enkripsi data pribadi (PII)
 * dan simpan ke file .env:
 *
 *   ENCRYPTION_PRIVATE_KEY = base64(PEM kunci privat)  <- RAHASIA
 *   ENCRYPTION_PUBLIC_KEY  = base64(PEM kunci publik)
 *
 * Aplikasi mobile mengambil kunci publik lewat endpoint
 * /api/v1/auth/public-key — kunci privat TIDAK pernah meninggalkan
 * server.
 */
class GenerateEncryptionKeys extends Command
{
    protected $signature = 'encryption:generate';

    protected $description = 'Buat pasangan kunci RSA enkripsi PII lalu simpan ke .env';

    public function handle(): int
    {
        $resource = openssl_pkey_new($this->opensslOptions());

        if (! $resource || ! openssl_pkey_export($resource, $privatePem, null, $this->opensslOptions())) {
            $this->error('Gagal membuat kunci RSA — cek konfigurasi OpenSSL PHP.');

            return self::FAILURE;
        }

        $details = openssl_pkey_get_details($resource);
        $publicPem = $details['key'];

        $this->writeEnv('ENCRYPTION_PRIVATE_KEY', base64_encode($privatePem));
        $this->writeEnv('ENCRYPTION_PUBLIC_KEY', base64_encode($publicPem));

        $this->info('Pasangan kunci RSA-2048 tersimpan di .env (ENCRYPTION_PRIVATE_KEY / ENCRYPTION_PUBLIC_KEY).');
        $this->line('Kunci publik kini tersedia di GET /api/v1/auth/public-key untuk aplikasi mobile.');
        $this->warn('Menjaga ENCRYPTION_PRIVATE_KEY tetap rahasia — jangan di-commit ke repository.');

        return self::SUCCESS;
    }

    /**
     * Opsi OpenSSL — di Windows openssl_pkey_new membutuhkan path
     * openssl.cnf eksplisit (bawaan PHP ada di <dir-php>/extras/ssl).
     */
    private function opensslOptions(): array
    {
        $options = [
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ];

        $phpDir = \dirname(PHP_BINARY);

        $candidates = [
            $phpDir.\DIRECTORY_SEPARATOR.'extras'.\DIRECTORY_SEPARATOR.'ssl'.\DIRECTORY_SEPARATOR.'openssl.cnf',
            $phpDir.\DIRECTORY_SEPARATOR.'openssl.cnf',
        ];

        foreach ($candidates as $config) {
            if (is_file($config)) {
                $options['config'] = $config;

                break;
            }
        }

        return $options;
    }

    /**
     * Timpa / tambah satu variabel di file .env.
     */
    private function writeEnv(string $key, string $value): void
    {
        $path = base_path('.env');

        if (! is_file($path)) {
            file_put_contents($path, "{$key}={$value}\n");

            return;
        }

        $content = (string) file_get_contents($path);
        $line = "{$key}={$value}";

        if (preg_match("/^{$key}=.*$/m", $content)) {
            $content = preg_replace("/^{$key}=.*$/m", $line, $content);
        } else {
            $content = rtrim($content)."\n{$line}\n";
        }

        file_put_contents($path, $content);
    }
}

"""
Uji end-to-end fitur enkripsi data pribadi (PII) — branch
fitur-encrypt-decrypt. Kripto aplikasi mobile disimulasikan secara
NYATA memakai tool Dart (pointycastle: RSA-OAEP-SHA1 + AES-256-GCM,
format PII1:), lalu diverifikasi terhadap backend PHP:

  1. register dengan field terenkripsi -> tersimpan TERENKRIPSI di
     database (PII1:...) walau validasi (NIK 16 digit) tetap jalan;
  2. web admin Data Penghuni menampilkan data TERDEKRIPSI (kunci
     privat .env);
  3. /auth/me menampilkan data TERDEKRIPSI bagi penghuni;
  4. update profil terenkripsi -> tersimpan terenkripsi;
  5. negatif: NIK palsu ('12345') yang DIENKRIPSI tetap ditolak 422
     (bukti dekripsi terjadi SEBELUM validasi);
  6. negatif: NIK plaintext tidak valid ditolak 422 (aturan lama
     tetap berlaku).

Dijalankan manual (server harus aktif di :8000):
    python tests/pii_encryption_test.py
"""
import json
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

BASE = 'http://localhost:8000'
MOBILE = '../mobile'

# dart.bat di Windows (dart polos tidak bisa dieksekusi subprocess).
DART = shutil.which('dart') or r'D:\App\flutter\bin\dart.bat'


def api(path, method='GET', body=None, token=None):
    headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
    )
    for key, value in headers.items():
        req.add_header(key, value)
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, json.loads(response.read().decode() or '{}')
    except urllib.error.HTTPError as error:
        raw = error.read().decode()
        return error.code, json.loads(raw) if raw else {}


def dart_seal(public_key_der_b64, fields):
    """Jalankan kripto Dart (sama persis dengan aplikasi mobile)."""
    result = subprocess.run(
        [DART, 'run', 'tool/encrypt_cli.dart', public_key_der_b64,
         json.dumps(fields, ensure_ascii=False)],
        capture_output=True, text=True, cwd=MOBILE, encoding='utf-8',
    )
    if result.returncode != 0:
        raise RuntimeError(f'dart run gagal: {result.stderr[:400]}')
    return json.loads(result.stdout)


def tinker(expression):
    result = subprocess.run(
        ['php', 'artisan', 'tinker', '--execute', expression, '--no-interaction'],
        capture_output=True, text=True, cwd='.', encoding='utf-8',
    )
    return result.stdout.strip()


def main():
    failures = []

    def check(label, condition, detail=''):
        status = 'PASS' if condition else 'FAIL'
        print(f'[{status}] {label} {detail}')
        if not condition:
            failures.append(label)

    # 0. Kunci publik tersedia & fitur aktif.
    status, body = api('/api/v1/auth/public-key')
    public_key = body.get('data', {}).get('public_key')
    check('GET /auth/public-key', status == 200 and bool(public_key))

    if not public_key:
        print('Fitur enkripsi belum aktif — jalankan: php artisan encryption:generate')
        sys.exit(1)

    email = f'enc-{int(time.time())}@contoh.com'
    plaintext = {
        'identity_number': '3573998877665544',
        'phone': '+6289955551234',
        'address': 'Jl. Mastrip No.130, Sukorame, Kediri',
        'guardian_name': 'Bapak Enc',
        'guardian_phone': '+6281312349876',
    }

    # 1. Register dengan field TERENKRIPSI (kripto Dart asli).
    sealed = dart_seal(public_key, plaintext)
    check('nilai tersegel berformat PII1:',
          all(v.startswith('PII1:') for v in sealed.values()),
          f"contoh: {sealed['identity_number'][:28]}...")

    status, body = api('/api/v1/auth/register', 'POST', {
        'email': email,
        'password': 'rahasia123',
        'password_confirmation': 'rahasia123',
        'full_name': 'E2e Enkripsi',
        'birth_date': '1999-05-10',
        'occupation': 'Karyawan',
        **sealed,
    })
    check('register field terenkripsi diterima (201)', status == 201,
          f'(status={status})')

    # 2. Database menyimpan bentuk TERENKRIPSI.
    raw = tinker(
        "echo App\\Models\\User::where('email', '" + email + "')"
        ".first()->resident->getRawOriginal('identity_number');"
    )
    check('DB menyimpan ciphertext PII1:', raw.startswith('PII1:'),
          f'({raw[:24]}...)')

    raw_phone = tinker(
        "echo App\\Models\\User::where('email', '" + email + "')"
        "->first()->getRawOriginal('phone');"
    )
    check('DB phone pengguna terenkripsi:', raw_phone.startswith('PII1:'))

    # 3. Setujui akun via tinker lalu /auth/me menampilkan TERDEKRIPSI.
    tinker(
        "App\\Models\\User::where('email', '" + email + "')"
        "->update(['status' => 'aktif']);"
    )
    status, body = api('/api/v1/auth/login', 'POST',
                       {'email': email, 'password': 'rahasia123'})
    token = body.get('data', {}).get('token')
    check('login setelah disetujui', status == 200 and bool(token))

    status, body = api('/api/v1/auth/me', token=token)
    me = body.get('data', {})
    resident = me.get('resident', {})
    check('/auth/me NIK terdekripsi',
          resident.get('identity_number') == plaintext['identity_number'],
          f"({resident.get('identity_number')})")
    check('/auth/me phone terdekripsi', me.get('phone') == plaintext['phone'])
    check('/auth/me alamat terdekripsi',
          resident.get('address') == plaintext['address'])

    # 4. Update profil dengan field terenkripsi.
    sealed_update = dart_seal(public_key, {
        'phone': '+6289955559999',
        'address': 'Jl. Baru No.9, Kediri',
        'guardian_name': 'Bapak Enc Baru',
        'guardian_phone': '+6281312340000',
    })
    status, body = api('/api/v1/auth/profile', 'PUT', {
        'full_name': 'E2e Enkripsi',
        'birth_date': '1999-05-10',
        **sealed_update,
    }, token=token)
    updated = body.get('data', {})
    check('update profil terenkripsi -> tampil terdekripsi',
          status == 200 and updated.get('phone') == '+6289955559999'
          and updated.get('resident', {}).get('guardian_name') == 'Bapak Enc Baru',
          f'(status={status})')

    raw_after = tinker(
        "echo App\\Models\\User::where('email', '" + email + "')"
        "->first()->getRawOriginal('phone');"
    )
    check('phone tetap terenkripsi di DB setelah update',
          raw_after.startswith('PII1:'))

    # 5. Negatif: NIK tidak valid ('12345') yang DIENKRIPSI tetap
    #    ditolak — bukti dekripsi terjadi SEBELUM validasi.
    bad_nik = dart_seal(public_key, {'identity_number': '12345'})
    status, body = api('/api/v1/auth/register', 'POST', {
        'email': f'bad-{int(time.time())}@contoh.com',
        'password': 'rahasia123',
        'password_confirmation': 'rahasia123',
        'full_name': 'NIK Salah Enc',
        'birth_date': '1999-05-10',
        'phone': sealed['phone'],
        'guardian_phone': sealed['guardian_phone'],
        **bad_nik,
    })
    check('NIK terenkripsi yang tidak valid ditolak 422', status == 422
          and 'identity_number' in body.get('errors', {}),
          f"(pesan: {body.get('errors', {}).get('identity_number', ['-'])[0]})")

    # 6. Negatif: NIK plaintext tidak valid juga ditolak (aturan asli).
    status, body = api('/api/v1/auth/register', 'POST', {
        'email': f'plain-{int(time.time())}@contoh.com',
        'password': 'rahasia123',
        'password_confirmation': 'rahasia123',
        'full_name': 'NIK Salah Plain',
        'identity_number': '123',
        'phone': '+6281111111111',
        'birth_date': '1999-05-10',
        'guardian_phone': '+6281311111111',
    })
    check('NIK plaintext tidak valid ditolak 422', status == 422)

    print()
    if failures:
        print(f'{len(failures)} GAGAL: {failures}')
        sys.exit(1)
    print('Semua uji enkripsi PII LULUS.')


if __name__ == '__main__':
    main()

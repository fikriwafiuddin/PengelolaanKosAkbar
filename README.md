# Sistem Informasi Pengelolaan Kost Akbar

Sistem terintegrasi multi-platform untuk Kost Akbar (Jl. Mastrip No.130, Sukorame, Mojoroto, Kota Kediri) — **Proyek Teknologi Terintegrasi, Kelompok 3, D3 Manajemen Informatika 2-D, PSDKU Politeknik Negeri Malang di Kota Kediri**.

## Arsitektur

Three-tier architecture: dua antarmuka client (aplikasi mobile **Flutter** untuk penghuni & dashboard web **React + shadcn/ui** untuk admin) yang terhubung ke satu backend **Laravel** (REST API + server-side rendering Inertia) dengan database **MySQL**.

```
┌────────────────────┐      ┌────────────────────┐
│  Mobile (Flutter)  │      │   Web Admin (React │
│  penghuni & calon  │      │   + shadcn/ui)     │
└─────────┬──────────┘      └─────────┬──────────┘
          │  REST API (Sanctum token) │ Inertia (session)
          └────────────┬──────────────┘
                ┌──────▼──────┐        ┌──────────────┐
                │  Laravel 13 │───────▶│ MySQL 8      │
                │  (API + Web)│        │ kost_akbar   │
                └─────────────┘        └──────────────┘
```

| Komponen | Lokasi | Teknologi |
|---|---|---|
| Backend (API + web) | `web/` | Laravel 13, Sanctum, Fortify, Inertia |
| Dashboard admin | `web/resources/js/` | React 19, shadcn/ui, Tailwind v4 |
| Aplikasi mobile | `mobile/` | Flutter, Provider, http |
| Database | MySQL | skema lengkap lihat `docs/kost-akbar.dbml` |

Struktur kode backend memakai pemisahan **Controller → Service → Model**: controller tipis (validasi via FormRequest, respons via Resource/Inertia), seluruh logika bisnis ada di `web/app/Services/`.

## Menjalankan (Laragon / Windows)

1. **Database** — pastikan MySQL aktif, lalu:

   ```bash
   mysql -u root -e "CREATE DATABASE pengelolaankosakbar CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
   ```

2. **Backend + web admin** (port 8000):

   ```bash
   cd web
   composer install
   cp .env.example .env          # lalu sesuaikan DB (default Laragon: root tanpa password)
   php artisan key:generate
   php artisan migrate:fresh --seed
   php artisan serve             # http://localhost:8000
   ```

   Build aset frontend (opsional untuk produksi; dev pakai `pnpm dev`):

   ```bash
   pnpm install && pnpm build
   ```

3. **Aplikasi mobile** (emulator Android memakai `10.0.2.2` untuk host):

   ```bash
   cd mobile
   flutter pub get
   flutter run                      # emulator Android
   flutter run --dart-define=API_URL=http://192.168.x.x:8000   # device fisik (IP komputer)
   ```

## Akun Demo

| Peran | Email | Sandi | Platform |
|---|---|---|---|
| Admin (Ririn Yudarina) | `admin@kostakbar.id` | `password` | Web `/login` |
| Penghuni (Dimas Pratama) | `dimaspratama@kostakbar.id` | `password` | Mobile |

Data demo mengikuti angka pada desain UI: **29 kamar** (Lantai 1-AC ×9 @Rp 600rb, Lantai 2-Reguler ×10 @Rp 500rb, Lantai 3-Reguler ×10 @Rp 450rb), **20 terisi / 9 kosong**, **20 penghuni aktif** dengan status pembayaran Oktober 2026: 16 lunas, 1 menunggu verifikasi, 3 belum bayar.

## Endpoint API v1 (`/api/v1`)

| Method | Path | Auth | Fungsi |
|---|---|---|---|
| POST | `/auth/register` | publik | registrasi calon penghuni (akun + identitas) |
| POST | `/auth/login` | publik | login, terbitkan token |
| POST | `/auth/logout` | token | cabut token device |
| GET | `/auth/me` | token | profil + identitas + kamar disewa |
| GET | `/rooms?q=&type=&status=&max_price=` | publik | katalog + pencarian |
| GET | `/rooms/{id}` | publik | detail kamar |
| GET | `/facilities` | publik | daftar fasilitas |

## Sprint 1 (28 Sep – 10 Okt 2026) ✅

- [x] Registrasi & login calon penghuni/penghuni (mobile)
- [x] Penghuni melihat profil identitas (mobile)
- [x] Admin melihat daftar data penghuni (web)
- [x] Admin menambah, mengupdate, menghapus data kamar (web)
- [x] Calon penghuni/penghuni melihat katalog kamar (mobile)
- [x] Pencarian kamar berdasarkan kategori/kriteria (mobile + web)
- [x] Admin mencetak katalog kamar (web, `/rooms/print`)

Menu **Verifikasi Pembayaran** (Sprint 2), **Chat & Pengumuman** (Sprint 3), dan **Laporan Keuangan** (Sprint 4) sudah tampil di sidebar web & bottom nav mobile sebagai penanda sprint berikutnya.

## Pengujian

```bash
# Web admin — 18 uji end-to-end (login, dashboard, CRUD kamar, filter, cetak, gate peran)
cd web && php artisan serve &
python tests/web_flow_test.py

# Mobile
cd mobile && flutter analyze && flutter test
```

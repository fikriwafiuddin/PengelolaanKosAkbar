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
   python scripts/generate_room_images.py   # foto placeholder 29 kamar (sekali saja)
   python scripts/generate_payment_proof.py  # bukti transfer demo (sekali saja)
   php artisan migrate:fresh --seed
   php artisan storage:link      # symlink penyajian foto kamar & bukti bayar
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
| Penghuni — tagihan belum bayar (Tegar Nugroho) | `tegarnugroho@kostakbar.id` | `password` | Mobile |
| Penghuni — bayaran menunggu verifikasi (Satria Wibowo) | `satriawibowo@kostakbar.id` | `password` | Mobile |
| Calon penghuni — menunggu validasi | `pending@kostakbar.id` | `password` | (login ditolak sampai disetujui) |

Data demo mengikuti angka pada desain UI: **29 kamar** (Lantai 1-AC ×9 @Rp 600rb, Lantai 2-Reguler ×10 @Rp 500rb, Lantai 3-Reguler ×10 @Rp 450rb), **20 terisi / 9 kosong**, **20 penghuni aktif** dengan status pembayaran Oktober 2026: 16 lunas, 1 menunggu verifikasi, 3 belum bayar.

## Endpoint API v1 (`/api/v1`)

| Method | Path | Auth | Fungsi |
|---|---|---|---|
| POST | `/auth/register` | publik | registrasi calon penghuni — NIK 16 digit, usia ≥ 18, penanggung jawab wajib; akun berstatus `menunggu_validasi` (tanpa token) |
| POST | `/auth/login` | publik | login, terbitkan token (ditolak selama menunggu validasi/ditolak) |
| POST | `/auth/logout` | token | cabut token device |
| GET | `/auth/me` | token | profil + identitas + kamar disewa |
| PUT | `/auth/profile` | token | ubah profil penghuni (email & NIK tetap) |
| GET | `/rooms?q=&type=&status=&max_price=&sort=` | publik | katalog + pencarian; `sort=asc\|desc` urut nomor kamar numerik |
| GET | `/rooms/{id}` | publik | detail kamar (termasuk `image_url` relatif) |
| GET | `/facilities` | publik | daftar fasilitas |
| GET | `/bookings` | token | riwayat pemesanan kamar milik penghuni |
| POST | `/bookings` | token | pesan kamar (`room_id`, `start_date`, `duration_months` 1–12) — tagihan bulanan dibuat otomatis, jatuh tempo tiap tanggal 25 |
| GET | `/invoices` | token | rincian tagihan penghuni + ringkasan total (belum bayar, jatuh tempo terdekat) |
| GET | `/invoices/{id}` | token | detail satu tagihan + riwayat pembayarannya (404 bila bukan milik sendiri) |
| POST | `/invoices/{id}/payments` | token | kirim pembayaran — `amount`, `method` transfer/tunai, `proof` gambar (wajib untuk transfer) |
| GET | `/notifications` | token | notifikasi pengingat pembayaran + jumlah belum dibaca |
| POST | `/notifications/mark-read` | token | tandai semua notifikasi terbaca |

Admin web: `PUT /residents/{user}/validation` (Terima/Tolak akun baru) dari halaman **Data Penghuni**, serta `GET /payments` + `PUT /payments/{id}/verification` (verifikasi pembayaran) dan `GET /payments/{id}/receipt` (kuitansi siap cetak) dari halaman **Verifikasi Pembayaran**.

## Sprint 1 (28 Sep – 10 Okt 2026) ✅

- [x] Registrasi & login calon penghuni/penghuni (mobile)
- [x] Penghuni melihat profil identitas (mobile)
- [x] Admin melihat daftar data penghuni (web)
- [x] Admin menambah, mengupdate, menghapus data kamar (web)
- [x] Calon penghuni/penghuni melihat katalog kamar (mobile)
- [x] Pencarian kamar berdasarkan kategori/kriteria (mobile + web)
- [x] Admin mencetak katalog kamar (web, `/rooms/print`)

Menu **Chat & Pengumuman** (Sprint 3) dan **Laporan Keuangan** (Sprint 4) sudah tampil di sidebar web & bottom nav mobile sebagai penanda sprint berikutnya.

### Revisi Sprint 1 (branch `sprint1rev`)

- [x] **Alur persetujuan registrasi** — pendaftar baru berstatus *menunggu validasi*, tidak dapat login; mobile menampilkan halaman menunggu; admin menyetujui/menolak dari halaman Data Penghuni
- [x] **Validasi registrasi** — NIK tepat 16 digit, usia minimal 18 tahun, kontak penanggung jawab wajib (semua pesan bahasa Indonesia)
- [x] **Manajemen profil** — penghuni dapat mengubah profil (email & NIK terkunci)
- [x] **Data Penghuni fokus biodata** — kolom identitas + penanggung jawab + status akun (data pembayaran dipisah ke sprint sewa)
- [x] **Urutan kamar numerik** — 1, 2, …, 29 (bukan urutan teks) + kontrol arah urut di web
- [x] **Foto kamar** — unggah/ganti/hapus oleh admin (jpg/png/webp ≤ 2 MB), tampil di web & mobile, placeholder 29 kamar via `scripts/generate_room_images.py`

## Sprint 2 (11 – 24 Okt 2026) ✅ — branch `sprint2`

- [x] **Pemesanan kamar** (mobile) — dari detail kamar kosong: pilih tanggal mulai + durasi sewa 1–12 bulan, rincian total sebelum konfirmasi; kamar otomatis terisi, satu pemesanan aktif per penghuni
- [x] **Rincian & total tagihan sewa bulanan** (mobile, tab Tagihan) — ringkasan total belum dibayar + jatuh tempo terdekat, daftar tagihan per periode dengan penanda terlambat
- [x] **Input nominal & upload bukti pembayaran** (mobile) — nominal (maks total tagihan), metode transfer (bukti wajib, multipart upload) / tunai; duplikat kirim ditolak selama menunggu verifikasi
- [x] **Verifikasi pembayaran** (web, menu Verifikasi Pembayaran) — tab status + pencarian, pratinjau bukti bayar, Terima/Tolak dengan konfirmasi
- [x] **Cetak kuitansi** (web) — nomor kuitansi berurutan `KA-YYYY-NNNN` terbit otomatis saat diterima; halaman kuitansi siap cetak (`/payments/{id}/receipt`)
- [x] **Notifikasi reminder pembayaran** (fitur baru) — scheduler harian `payments:remind` mengingatkan tagihan belum bayar yang mendekati / melewati jatuh tempo; muncul sebagai lonceng di tab Tagihan mobile

Menjalankan pengingat secara manual (tanpa menunggu scheduler):

```bash
php artisan payments:remind          # ingatkan jatuh tempo ≤ 5 hari ke depan + yang terlambat
php artisan schedule:list            # cek jadwal terdaftar (harian 08:00)
```

Untuk scheduler berjalan terus-menerus di lokal: `php artisan schedule:work`.

## Pengujian

```bash
# Web admin — 40 uji end-to-end (Sprint 1 + revisi + Sprint 2:
# persetujuan registrasi, CRUD kamar, pemesanan -> tagihan -> bayar ->
# verifikasi -> kuitansi, gate peran)
cd web && php artisan serve &
python tests/web_flow_test.py

# Mobile — 5 uji widget (login, registrasi, tagihan + validasi bayar)
cd mobile && flutter analyze && flutter test
```

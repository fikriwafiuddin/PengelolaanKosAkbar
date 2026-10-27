# Panduan Setup Firebase — Kost Akbar

Integrasi Firebase bersifat **opsional dengan fallback otomatis**:

| Fitur | Tanpa Firebase (default) | Dengan Firebase |
|---|---|---|
| Notifikasi reminder / chat / verifikasi | tersimpan di database (badge lonceng di aplikasi) | + **push notification FCM** — muncul sebagai notifikasi sistem walau aplikasi tertutup |
| Chat | polling tiap 4 detik | **realtime Firestore** — pesan muncul instan |

MySQL (Laravel) tetap satu-satunya sumber kebenaran: pesan dikirim lewat API Laravel, server menyalinannya (dual-write) ke Firestore, lalu aplikasi mobile menerima update lewat stream Firestore.

---

## 1. Buat project Firebase

1. Buka <https://console.firebase.google.com> → **Add project** (mis. `kost-akbar`).
2. Google Analytics tidak wajib — boleh dinonaktifkan.

## 2. Sambungkan aplikasi Android

1. **Project Overview → Android app** (ikon Android) untuk menambah aplikasi.
2. **Android package name**: `com.example.mobile` (applicationId di
   `mobile/android/app/build.gradle.kts` — bila diubah, samakan).
3. App nickname: `Kost Akbar`. Debug signing certificate SHA-1: opsional
   (tidak wajib untuk FCM/Firestore).
4. Unduh **`google-services.json`**. Buka berkas itu dengan teks editor —
   nilai-nilainya dipakai di langkah berikutnya.

## 3. Isi konfigurasi aplikasi mobile

Edit `mobile/lib/config/firebase_config.dart` — isi `kFirebaseOptions`
mengambil dari `google-services.json`:

```dart
const FirebaseOptions kFirebaseOptions = FirebaseOptions(
  apiKey: 'AIza...            ', // google-services.json -> api_key.current_key
  projectId: 'kost-akbar-xxxxx', // -> project_id
  messagingSenderId: '123456789', // -> project_number
  appId: '1:123456789:android:xx', // -> mobilesdk_app_id
);
```

Nilai ini tidak rahasia (sama yang terbungkus di dalam APK) — aman di-commit.
Restart aplikasi (`flutter run`) — kini chat realtime & push aktif.

## 4. Aktifkan Firestore + aturan keamanan

1. **Build → Firestore Database → Create database** (pilih lokasi
   `asia-southeast2`/Singapore, mode **production**).
2. Tab **Rules** — pakai aturan berikut lalu **Publish**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat: klien hanya boleh MEMBACA (via stream). Semua penulisan
    // dilakukan server Laravel lewat service account — klien tidak
    // bisa menyuntik pesan palsu.
    match /chatRooms/{roomId}/messages/{messageId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

> Tanpa Firebase Auth, pembatasan baca per-penghuni tidak bisa divalidasi
> di sisi Firestore. Aturan di atas aman untuk data chat kos yang tidak
> rahasia; bila ingin lebih ketat, aktifkan Firebase Auth lalu cocokkan
> klaim token di rules.

## 5. Pasang service account di backend

1. **Project settings (⚙) → Service accounts → Generate new private key**
   → unduh berkas JSON.
2. Rename menjadi `service-account.json` dan letakkan di:

   ```
   web/storage/app/firebase/service-account.json
   ```

   (Folder ini sudah di-gitignore — kredensial tidak ikut ter-commit.)
3. Backend otomatis menggunakannya: push FCM + dual-write Firestore
   aktif tanpa konfigurasi lain. Cek status:

   ```bash
   cd web
   php artisan tinker --execute="echo app(App\Services\FcmService::class)->enabled() ? 'AKTIF' : 'BELUM AKTIF';"
   ```

## 6. Uji end-to-end

```bash
# 1. Jalankan backend
cd web && php artisan serve

# 2. Jalankan aplikasi di device/emulator YANG PUNYA layanan Google
#    (emulator AVD standar sudah memenuhi), login penghuni mana pun.
cd ../mobile && flutter run

# 3. Uji push chat: dari web admin (admin@kostakbar.id) buka
#    Chat & Pengumuman -> kirim pesan / pengumuman.
#    - Aplikasi di foreground  : pesan muncul instan (stream Firestore)
#    - Aplikasi di background  : muncul notifikasi sistem (FCM)

# 4. Uji push reminder:
php artisan payments:remind
#    -> device penghuni dengan tagihan belum bayar menerima notifikasi

# 5. Uji push verifikasi: admin menerima pembayaran -> penghuni
#    menerima push "Pembayaran diterima" beserta nomor kuitansi.
```

## Struktur data Firestore

```
chatRooms (collection)
 └── {roomId}                        = id tabel chat_rooms (MySQL)
      └── messages (collection)
           └── {messageId}           = id tabel messages (MySQL)
                id            int
                chatRoomId    int
                body          string
                isAnnouncement bool
                senderId      int
                senderName    string
                senderRole    string
                sentAt        timestamp
```

## Catatan

- **Tanpa mengikuti panduan ini pun aplikasi tetap berjalan normal**
  (polling chat + notifikasi database) — tidak ada langkah wajib.
- iOS belum dikonfigurasi (perlu `GoogleService-Info.plist` + APNs key);
  proyek ini memaket APK Android.
- Bila ingin memakai `flutterfire configure` resmi, hasilkan
  `firebase_options.dart` lalu samakan isinya ke
  `mobile/lib/config/firebase_config.dart` (atau ganti import-nya).

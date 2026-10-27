import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi Firebase aplikasi mobile Kost Akbar.
///
/// **Nilai `null` = Firebase NONAKTIF** — aplikasi tetap berjalan
/// penuh memakai polling chat + notifikasi database (fallback).
///
/// Untuk mengaktifkan (panduan lengkap: docs/FIREBASE_SETUP.md):
/// 1. Buat project di https://console.firebase.google.com
/// 2. Tambahkan aplikasi Android dengan package name
///    `com.example.mobile`, unduh `google-services.json`
/// 3. Salin nilai apiKey / projectId / messagingSenderId / appId
///    dari berkas itu ke [kFirebaseOptions] di bawah, lalu hot
///    restart. Nilai ini tidak rahasia (sama yang ikut terbungkus
///    di dalam APK).
const FirebaseOptions? kFirebaseOptions = null;

// Contoh hasil isian (jangan di-uncomment sebelum nilai asli ada):
// const FirebaseOptions kFirebaseOptions = FirebaseOptions(
//   apiKey: 'AIza...',
//   projectId: 'kost-akbar-xxxxx',
//   messagingSenderId: '123456789012',
//   appId: '1:123456789012:android:abcdef0123456789',
// );

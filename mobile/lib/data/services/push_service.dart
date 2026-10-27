import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/firebase_config.dart';
import '../api_client.dart';

/// Jembatan Firebase pada aplikasi mobile: izin notifikasi,
/// registrasi token FCM ke server, dan akses Firestore.
///
/// Semua metode aman dipanggil walau Firebase belum dikonfigurasi
/// ([kFirebaseOptions] null) — menjadi no-op dan aplikasi memakai
/// fallback (polling chat + notifikasi database).
class PushService {
  PushService._();

  /// Kunci penyimpanan token FCM terakhir yang teregistrasi.
  static const String _tokenKey = 'fcm_token';

  /// Apakah Firebase aktif pada sesi aplikasi ini.
  static bool get enabled =>
      kFirebaseOptions != null && Firebase.apps.isNotEmpty;

  /// Apakah Firestore realtime siap dipakai untuk chat.
  static bool get firestoreEnabled => enabled;

  /// Siapkan push notification setelah login berhasil: minta izin,
  /// daftarkan device ke FCM, lalu kirim token ke server setiap kali
  /// Firebase menerbitkannya (termasuk perputaran token).
  static Future<void> activate(ApiClient client) async {
    if (!enabled) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Notifikasi foreground tetap tampil di Android/iOS terbaru.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Pasang listener dulu agar token pertama tidak terlewat.
      messaging.onRegistered.listen((token) => _registerToken(client, token));
      await messaging.register();
    } catch (_) {
      // Gagal inisialisasi (mis. perangkat tanpa layanan Google) —
      // aplikasi tetap jalan tanpa push.
    }
  }

  /// Hapus token device dari server saat logout.
  static Future<void> deactivate(ApiClient client) async {
    if (!enabled) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final registered = prefs.getString(_tokenKey);

      if (registered != null && registered.isNotEmpty) {
        await client.delete('/api/v1/devices', body: {'token': registered});
        await prefs.remove(_tokenKey);
      }
    } catch (_) {
      // Abaikan kegagalan jaringan saat logout.
    }
  }

  /// Daftarkan token ke server (bila berbeda dari yang terakhir).
  static Future<void> _registerToken(ApiClient client, String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getString(_tokenKey) == token) {
        return;
      }

      await client.post('/api/v1/devices', body: {
        'token': token,
        'platform': 'android',
      });
      await prefs.setString(_tokenKey, token);
    } catch (_) {
      // Token akan dicoba didaftarkan ulang saat login berikutnya.
    }
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/firebase_config.dart';
import '../api_client.dart';

/// Jembatan Firebase pada aplikasi mobile: izin notifikasi,
/// registrasi token FCM ke server, tampilan notifikasi foreground,
/// dan akses Firestore.
///
/// Semua metode aman dipanggil walau Firebase belum dikonfigurasi
/// ([kFirebaseOptions] null) — menjadi no-op dan aplikasi memakai
/// fallback (polling chat + notifikasi database).
///
/// Setiap langkah dicatat ke console (debugPrint) supaya masalah
/// registrasi mudah terlihat saat `flutter run`.
class PushService {
  PushService._();

  /// Kunci penyimpanan token FCM terakhir yang teregistrasi.
  static const String _tokenKey = 'fcm_token';

  /// Kanal notifikasi Android untuk push foreground.
  static const String _channelId = 'push_kost_akbar';

  static FlutterLocalNotificationsPlugin? _localNotifications;

  ///true bila activate() sedang berjalan (penjaga retry).
  static bool _activating = false;

  /// Apakah Firebase aktif pada sesi aplikasi ini.
  static bool get enabled =>
      kFirebaseOptions != null && Firebase.apps.isNotEmpty;

  /// Apakah Firestore realtime siap dipakai untuk chat.
  static bool get firestoreEnabled => enabled;

  /// Siapkan push notification setelah login berhasil: minta izin,
  /// daftarkan device ke FCM, kirim token ke server, pasang tampilan
  /// notifikasi foreground, dan pantau perputaran token.
  ///
  /// Aman dipanggil berulang (idempoten) — dipanggil ulang saat
  /// shell utama terbuka untuk menutupi kasus backend sempat mati
  /// saat login.
  static Future<void> activate(ApiClient client) async {
    if (!enabled || _activating) {
      return;
    }

    _activating = true;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] izin notifikasi: ${settings.authorizationStatus}');

      await _setupForegroundDisplay(messaging);

      // Pasang listener dulu agar token pertama tidak terlewat.
      messaging.onRegistered.listen((token) {
        debugPrint('[FCM] token diterima: ${token.substring(0, token.length > 24 ? 24 : token.length)}…');
        _registerToken(client, token);
      });

      await messaging.register();
      debugPrint('[FCM] register() dipanggil — menunggu token…');
    } catch (e) {
      // Gagal inisialisasi (mis. emulator tanpa layanan Google, atau
      // appId/projectId di firebase_config.dart salah) — tampilkan
      // penyebabnya di console, aplikasi tetap jalan tanpa push.
      debugPrint('[FCM] AKTIVASI GAGAL: $e');
    } finally {
      _activating = false;
    }
  }

  /// Tampilkan push juga saat aplikasi sedang TERBUKA. Di Android,
  /// pesan foreground tidak ditampilkan sistem — perlu notifikasi
  /// lokal; di iOS cukup presentation options.
  static Future<void> _setupForegroundDisplay(FirebaseMessaging messaging) async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          'Notifikasi Kost Akbar',
          description: 'Pengingat pembayaran, pengumuman, dan pesan chat.',
          importance: Importance.high,
        ));

    _localNotifications = plugin;

    // firebase_messaging 17: stream onMessage bersifat statis —
    // diakses lewat kelas, bukan instance.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      debugPrint('[FCM] pesan foreground: ${notification?.title}');

      if (notification == null) {
        return;
      }

      plugin.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Notifikasi Kost Akbar',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['type']?.toString(),
      );
    });
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
    } catch (e) {
      debugPrint('[FCM] gagal lepas token saat logout: $e');
    }
  }

  /// Daftarkan token ke server. Bila gagal (mis. backend belum
  /// hidup), token TIDAK dicatat sebagai terkirim sehingga dicoba
  /// lagi pada activate() berikutnya.
  static Future<void> _registerToken(ApiClient client, String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await client.post('/api/v1/devices', body: {
        'token': token,
        'platform': 'android',
      });
      await prefs.setString(_tokenKey, token);
      debugPrint('[FCM] token TERDAFTAR ke server');
    } catch (e) {
      debugPrint('[FCM] gagal daftar token ke server (akan dicoba lagi): $e');
    }
  }
}

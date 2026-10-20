import '../api_client.dart';
import '../models/app_notification.dart';

/// Notifikasi penghuni — pengingat pembayaran (endpoint privat
/// /notifications).
class NotificationService {
  NotificationService(this._client);

  final ApiClient _client;

  /// Daftar notifikasi terbaru + jumlah belum dibaca.
  Future<NotificationList> list() async {
    final json =
        await _client.get('/api/v1/notifications') as Map<String, dynamic>;

    return NotificationList(
      notifications: (json['data'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tandai semua notifikasi sudah dibaca.
  Future<void> markAllRead() async {
    await _client.post('/api/v1/notifications/mark-read');
  }
}

/// Notifikasi penghuni (pengingat pembayaran, dst.) dari API /notifications.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.invoiceId,
    this.roomNumber,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Notifikasi',
        body: json['body'] as String? ?? '',
        invoiceId: (json['invoice_id'] as num?)?.toInt(),
        roomNumber: json['room_number'] as String?,
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  final String id;
  final String title;
  final String body;
  final int? invoiceId;
  final String? roomNumber;
  final String? readAt;
  final String createdAt;

  bool get isRead => readAt != null;
}

/// Hasil daftar notifikasi + jumlah belum dibaca.
class NotificationList {
  const NotificationList({required this.notifications, required this.unreadCount});

  final List<AppNotification> notifications;
  final int unreadCount;
}

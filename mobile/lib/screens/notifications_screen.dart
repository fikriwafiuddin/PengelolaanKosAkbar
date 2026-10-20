import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/app_notification.dart';
import '../../data/services/notification_service.dart';
import '../../theme/app_theme.dart';

/// Daftar notifikasi penghuni — pengingat jatuh tempo tagihan sewa.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notifications;
  NotificationList? _list;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationService(context.read<ApiClient>());
    _fetch(markRead: false);
  }

  Future<void> _fetch({required bool markRead}) async {
    setState(() => _error = null);

    try {
      if (markRead) {
        await _notifications.markAllRead();
      }
      final list = await _notifications.list();
      setState(() => _list = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: () => _fetch(markRead: true),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta))
              : _error != null
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted)),
                    ])
                  : list == null || list.notifications.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 240),
                          Icon(Icons.notifications_off_outlined,
                              size: 44, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada notifikasi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          children: [
                            for (final notification in list.notifications)
                              _NotificationTile(notification: notification),
                            const SizedBox(height: 20),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isReminder = notification.title.toLowerCase().contains('tagihan');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isReminder
                    ? const Color(0xFFFEF3C7)
                    : AppColors.field,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReminder
                    ? Icons.schedule_rounded
                    : Icons.notifications_outlined,
                color: isReminder ? const Color(0xFFB45309) : AppColors.teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: notification.isRead
                                ? AppColors.textDark
                                : AppColors.terracotta,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

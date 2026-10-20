import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/invoice.dart';
import '../../data/services/invoice_service.dart';
import '../../data/services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../booking/bookings_history_screen.dart';
import '../notifications_screen.dart';
import 'invoice_detail_screen.dart';

/// Tab Tagihan: rincian & total tagihan sewa bulanan penghuni
/// (Sprint 2 — mengikuti desain UI "Tagihan").
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late final InvoiceService _invoices;
  late final NotificationService _notifications;
  InvoiceSummary? _summary;
  int _unreadNotifications = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invoices = InvoiceService(context.read<ApiClient>());
    _notifications = NotificationService(context.read<ApiClient>());
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);

    try {
      final results = await Future.wait([
        _invoices.myInvoices(),
        _notifications.list(),
      ]);
      final summary = results[0] as InvoiceSummary;
      final notificationList = results[1] as NotificationList;

      setState(() {
        _summary = summary;
        _unreadNotifications = notificationList.unreadCount;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final rupiah =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          // Lonceng notifikasi pengingat pembayaran
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ));
                  _fetch();
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.terracotta,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      '$_unreadNotifications',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Riwayat Pemesanan',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const BookingsHistoryScreen(),
            )),
            icon: const Icon(Icons.event_note_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.terracotta,
          onRefresh: _fetch,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta))
              : _error != null
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton(
                            onPressed: _fetch, child: const Text('Coba Lagi')),
                      ),
                    ])
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      children: [
                        // Ringkasan total tagihan
                        if (summary != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.terracotta, Color(0xFFC2542C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL TAGIHAN BELUM DIBAYAR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rupiah.format(summary.unpaidAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  summary.unpaidCount > 0
                                      ? '${summary.unpaidCount} tagihan menunggu dibayar'
                                      : 'Semua tagihan lunas 🎉',
                                  style:
                                      const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                if (summary.nextDueDate != null &&
                                    summary.unpaidCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jatuh tempo terdekat: '
                                    '${DateFormat('d MMMM yyyy', 'id_ID').format(summary.nextDueDate!)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Daftar tagihan per periode
                        if (summary != null && summary.invoices.isEmpty)
                          const _EmptyTagihan()
                        else
                          for (final invoice in summary?.invoices ?? <Invoice>[])
                            _InvoiceTile(invoice: invoice),

                        const SizedBox(height: 20),
                      ],
                    ),
        ),
      ),
    );
  }
}

/// Satu baris tagihan: periode, kamar, nominal, status.
class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = invoice.isOverdue
        ? (const Color(0xFFB91C1C), const Color(0xFFFEE2E2))
        : switch (invoice.status) {
            InvoiceStatus.lunas => (const Color(0xFF0F766E), const Color(0xFFE0F2F1)),
            InvoiceStatus.belumBayar =>
              (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
          };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.terracotta, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamar ${invoice.roomNumber} · ${invoice.periodLabel}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jatuh tempo ${invoice.dueDateFormatted}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (invoice.hasPendingPayment) ...[
                      const SizedBox(height: 3),
                      const Text(
                        'Menunggu verifikasi pengelola',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invoice.amountFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration:
                        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      invoice.isOverdue ? 'Terlambat' : invoice.statusLabel,
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTagihan extends StatelessWidget {
  const _EmptyTagihan();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 44, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Belum ada tagihan',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tagihan muncul setelah Anda memesan kamar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

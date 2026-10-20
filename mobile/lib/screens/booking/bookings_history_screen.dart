import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/booking.dart';
import '../../data/services/booking_service.dart';
import '../../theme/app_theme.dart';

/// Riwayat pemesanan kamar milik penghuni.
class BookingsHistoryScreen extends StatefulWidget {
  const BookingsHistoryScreen({super.key});

  @override
  State<BookingsHistoryScreen> createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  late final BookingService _bookings;
  List<Booking> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookings = BookingService(context.read<ApiClient>());
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);

    try {
      final list = await _bookings.myBookings();
      setState(() => _list = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pemesanan')),
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
                  : _list.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 240),
                          Icon(Icons.event_busy_outlined,
                              size: 44, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada pemesanan.\nPesan kamar dari katalog Beranda.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppColors.textMuted, height: 1.6),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          children: [
                            for (final booking in _list)
                              _BookingTile(booking: booking),
                            const SizedBox(height: 20),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (booking.status) {
      BookingStatus.aktif => (const Color(0xFF0F766E), const Color(0xFFE0F2F1)),
      BookingStatus.menunggu => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
      _ => (const Color(0xFF6B7280), const Color(0xFFE5E7EB)),
    };

    final unpaid = booking.invoices
        .where((invoice) => invoice.status.name == 'belumBayar')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kamar ${booking.roomNumber} · ${booking.roomType}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    booking.statusLabel,
                    style: TextStyle(
                        color: fg,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mulai ${DateFormat('d MMMM yyyy', 'id_ID').format(booking.startDate)} · ${booking.durationMonths} bulan',
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Total sewa ${booking.invoices.isNotEmpty ? booking.invoices.first.amountFormatted : booking.priceFormatted}'
              '${unpaid > 0 ? ' · $unpaid tagihan belum bayar' : ''}',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

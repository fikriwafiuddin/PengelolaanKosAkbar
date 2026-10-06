import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/room.dart';
import '../../data/services/room_service.dart';
import '../../theme/app_theme.dart';

/// Detail kamar: informasi lengkap, fasilitas, harga, dan status
/// (aktivitas "Lihat detail data kamar yang dipilih" pada Sprint 1).
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId, this.preview});

  final int roomId;

  /// Data awal (dari kartu katalog) agar halaman langsung terisi
  /// sebelum detail lengkap diambil dari server.
  final Room? preview;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late final RoomService _rooms;
  Room? _room;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rooms = RoomService(context.read<ApiClient>());
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);

    try {
      final room = await _rooms.detail(widget.roomId);
      setState(() => _room = room);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room ?? widget.preview;
    final (fg, bg) = room?.statusColors ?? (Colors.white, Colors.white);
    final price = room == null
        ? '-'
        : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(room.priceMonthly);

    return Scaffold(
      appBar: AppBar(title: Text(room?.title ?? 'Detail Kamar')),
      body: SafeArea(
        child: _loading && room == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _error != null && room == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _fetch, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // Kartu utama
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      room!.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      room.statusLabel,
                                      style: TextStyle(
                                        color: fg,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(room.type,
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 13)),
                              const Divider(height: 28),
                              const Text(
                                'HARGA SEWA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      color: AppColors.terracotta,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 26,
                                    ),
                                  ),
                                  const Text('  / bulan',
                                      style: TextStyle(
                                          color: AppColors.textMuted, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Fasilitas
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FASILITAS KAMAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (room.facilities.isEmpty)
                                const Text('Belum ada fasilitas terdaftar.',
                                    style:
                                        TextStyle(color: AppColors.textMuted, fontSize: 13))
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final facility in room.facilities)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.field,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_outline_rounded,
                                                size: 15, color: AppColors.teal),
                                            const SizedBox(width: 6),
                                            Text(facility.name,
                                                style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: AppColors.textDark)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Deskripsi
                      if (room.description != null && room.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESKRIPSI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.description!,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.7,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Fitur pemesanan kamar akan tersedia pada Sprint 2.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}

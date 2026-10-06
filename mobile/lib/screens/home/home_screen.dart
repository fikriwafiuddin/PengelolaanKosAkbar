import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/room.dart';
import '../../data/services/room_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/room_card.dart';
import 'room_detail_screen.dart';

/// Beranda: katalog kamar + pencarian + filter tipe & status
/// (fitur Sprint 1: "lihat katalog kamar" dan "pencarian kamar").
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final RoomService _rooms;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  /// Filter tipe standar sesuai data Kost Akbar.
  static const List<String> _types = [
    'Semua',
    'Lantai 1 - AC',
    'Lantai 2 - Reguler',
    'Lantai 3 - Reguler',
  ];

  String _query = '';
  String _type = 'Semua';
  String? _status;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Room> _roomsList = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _rooms = RoomService(context.read<ApiClient>());
    _fetch();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_loadingMore &&
          _currentPage < _lastPage) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _loading = true);
    }
    setState(() => _error = null);

    try {
      final page = await _rooms.list(
        query: _query,
        type: _type == 'Semua' ? null : _type,
        status: _status,
      );

      setState(() {
        _roomsList = page.rooms;
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _total = page.total;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _loadingMore = true);

    try {
      final page = await _rooms.list(
        query: _query,
        type: _type == 'Semua' ? null : _type,
        status: _status,
        page: _currentPage + 1,
      );

      setState(() {
        _roomsList.addAll(page.rooms);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
      });
    } on ApiException {
      // Abaikan kegagalan muat lebih; pengguna bisa scroll ulang.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = value;
      _fetch(showLoading: false);
    });
  }

  void _openDetail(Room room) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDetailScreen(roomId: room.id, preview: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Sapaan
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${user?.resident?.fullName ?? user?.name ?? 'Penghuni'} 👋',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Cari kamar kos yang cocok untukmu',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pencarian
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kamar / fasilitas...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _query = '';
                          _fetch(showLoading: false);
                        },
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // Filter tipe
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _types[index] == _type;

                  return ChoiceChip(
                    label: Text(_types[index]),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _type = _types[index]);
                      _fetch(showLoading: false);
                    },
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                    selectedColor: AppColors.terracotta,
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Filter status
            Row(
              children: [
                const Spacer(),
                PopupMenuButton<String>(
                  initialValue: _status,
                  onSelected: (value) {
                    setState(() => _status = value.isEmpty ? null : value);
                    _fetch(showLoading: false);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: '', child: Text('Semua status')),
                    PopupMenuItem(value: 'kosong', child: Text('Tersedia')),
                    PopupMenuItem(value: 'terisi', child: Text('Terisi')),
                    PopupMenuItem(value: 'terbooking', child: Text('Terbooking')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: AppColors.terracotta),
                        const SizedBox(width: 6),
                        Text(
                          switch (_status) {
                            'kosong' => 'Tersedia',
                            'terisi' => 'Terisi',
                            'terbooking' => 'Terbooking',
                            _ => 'Semua status',
                          },
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info jumlah
            Text(
              '$_total kamar ditemukan',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // Daftar kamar
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta),
                ),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _fetch)
            else if (_roomsList.isEmpty)
              const _EmptyState()
            else ...[
              for (final room in _roomsList)
                RoomCard(room: room, onTap: () => _openDetail(room)),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ),
              if (_currentPage >= _lastPage && _roomsList.length > 6)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      'Semua ${NumberFormat.decimalPattern('id_ID').format(_total)} kamar sudah ditampilkan',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada kamar yang cocok.\nCoba ubah kata kunci atau filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}

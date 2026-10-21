import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/chat_room.dart';
import '../../data/services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'chat_room_screen.dart';

/// Tab Chat: daftar grup chat penghuni beserta badge belum dibaca
/// (Sprint 3 — mengikuti desain UI "Chat").
class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  late final ChatService _chat;
  ChatRoomList? _list;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chat = ChatService(context.read<ApiClient>());
    _fetch();
  }

  @override
  void dispose() {
    // Layar daftar dimuat ulang tiap dibuka (IndexedStack tidak dipakai),
    // jadi tidak perlu timer di sini.
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);

    try {
      final list = await _chat.rooms();
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
      appBar: AppBar(title: const Text('Chat')),
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
                  : list == null || list.rooms.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 240),
                          Icon(Icons.chat_outlined,
                              size: 44, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada grup chat.\nHubungi pengelola untuk info lebih lanjut.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppColors.textMuted, height: 1.6),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          children: [
                            for (final room in list.rooms)
                              _RoomTile(room: room),
                            const SizedBox(height: 20),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatRoomScreen(roomId: room.id, roomName: room.name),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.terracotta, Color(0xFFC2542C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      room.name.trim().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (room.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.terracotta,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          '${room.unreadCount}',
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.lastMessage != null
                          ? (room.lastMessage!.isAnnouncement
                              ? '📢 ${room.lastMessage!.body}'
                              : room.lastMessage!.body)
                          : 'Belum ada pesan',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: room.unreadCount > 0
                            ? AppColors.textDark
                            : AppColors.textMuted,
                        fontWeight: room.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${room.membersCount} anggota',
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted),
                  ),
                  if (room.lastMessage?.sentAtFormatted != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      room.lastMessage!.sentAtFormatted!,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/message.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/push_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Percakapan satu grup chat: gelembung pesan (pengumuman resmi
/// bergaya khusus) + komposer.
///
/// Sumber data pesan:
/// - Firebase aktif    -> stream Firestore realtime (instan, tanpa
///   polling); pengiriman tetap lewat API Laravel (satu sumber
///   kebenaran, server yang menyalin ke Firestore).
/// - Firebase nonaktif -> polling API tiap 4 detik (fallback).
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.roomId, required this.roomName});

  final int roomId;
  final String roomName;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final ChatService _chat;
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Message> _messages = [];
  Timer? _pollTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSub;
  late final int? _currentUserId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chat = ChatService(context.read<ApiClient>());
    _currentUserId = context.read<AuthProvider>().user?.id;
    _fetchInitial();

    if (PushService.firestoreEnabled) {
      _listenFirestore();
    } else {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollNew());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _streamSub?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchInitial() async {
    setState(() => _error = null);

    try {
      final messages = await _chat.messages(widget.roomId);
      setState(() => _messages
        ..clear()
        ..addAll(messages));
      _jumpToBottom();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Polling ringan: hanya pesan setelah id terakhir, tanpa menandai
  /// ulang baca (penanda sudah diset saat muat awal).
  Future<void> _pollNew() async {
    if (_error != null || _messages.isEmpty) return;

    try {
      final fresh = await _chat.messages(
        widget.roomId,
        afterId: _messages.last.id,
        markRead: false,
      );

      if (fresh.isNotEmpty && mounted) {
        setState(() => _messages.addAll(fresh));
        _jumpToBottom();
      }
    } on ApiException {
      // Koneksi sempat gagal — coba lagi pada tick berikutnya.
    }
  }

  /// Langganan realtime Firestore: dokumen
  /// chatRooms/{roomId}/messages diurutkan berdasarkan id pesan
  /// (id MySQL — server Laravel menyalin setiap pesan baru ke sini).
  void _listenFirestore() {
    _streamSub = FirebaseFirestore.instance
        .collection('chatRooms/${widget.roomId}/messages')
        .orderBy('id')
        .limitToLast(200)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) {
              return;
            }

            final previousLastId = _messages.isNotEmpty ? _messages.last.id : null;
            final messages = snapshot.docs.map(_messageFromDoc).toList();

            setState(() {
              _messages
                ..clear()
                ..addAll(messages);
              _loading = false;
            });

            if (messages.isNotEmpty && messages.last.id != previousLastId) {
              _jumpToBottom();
            }
          },
          onError: (_) {
            // Stream gagal (mis. rules belum dipasang) — kembali ke
            // polling supaya chat tetap hidup.
            _streamSub?.cancel();
            if (mounted && _pollTimer == null) {
              _pollTimer = Timer.periodic(
                const Duration(seconds: 4),
                (_) => _pollNew(),
              );
            }
          },
        );
  }

  /// Ubah dokumen Firestore menjadi model Message (isOwn dihitung
  /// dari id pengguna yang login).
  Message _messageFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final sentAt = data['sentAt'];

    final date = sentAt is Timestamp
        ? sentAt.toDate()
        : DateTime.tryParse(sentAt?.toString() ?? '') ?? DateTime.now();

    return Message(
      id: (data['id'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
      chatRoomId: widget.roomId,
      body: data['body'] as String? ?? '',
      isAnnouncement: data['isAnnouncement'] as bool? ?? false,
      sentAt: date.toIso8601String(),
      sentAtFormatted: DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date),
      isOwn: (data['senderId'] as num?)?.toInt() == _currentUserId,
      senderId: data['senderId'] as num?,
      senderName: data['senderName'] as String?,
      senderRole: data['senderRole'] as String?,
    );
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final message = await _chat.send(widget.roomId, body);
      _composer.clear();
      setState(() => _messages.add(message));
      _jumpToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e.errors.values.expand((messages) => messages).firstOrNull ??
                  e.message),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.roomName)),
      body: SafeArea(
        child: Column(
          children: [
            // Daftar pesan
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.terracotta))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                  onPressed: _fetchInitial,
                                  child: const Text('Coba Lagi')),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _MessageBubble(message: _messages[index]),
                        ),
            ),

            // Komposer
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 8,
                top: 8,
                bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan…',
                        filled: true,
                        fillColor: AppColors.field,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.terracotta,
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
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

/// Gelembung satu pesan: pengumuman resmi memanjang penuh dengan aksen
/// amber + ikon pengeras suara; pesan biasa kiri (orang lain) /
/// kanan (sendiri).
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    if (message.isAnnouncement) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF6D888)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 5),
                  Text(
                    'PENGUMUMAN RESMI${message.senderName != null ? ' · ${message.senderName}' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message.body,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: Color(0xFF78350F),
                ),
              ),
              if (message.sentAtFormatted != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message.sentAtFormatted!,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final isOwn = message.isOwn;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.terracotta : AppColors.field,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwn && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: message.senderRole == 'admin'
                        ? AppColors.teal
                        : AppColors.textMuted,
                  ),
                ),
              ),
            Text(
              message.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isOwn ? Colors.white : AppColors.textDark,
              ),
            ),
            if (message.sentAtFormatted != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  message.sentAtFormatted!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isOwn
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

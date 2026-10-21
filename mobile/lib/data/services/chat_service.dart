import '../api_client.dart';
import '../models/chat_room.dart';
import '../models/message.dart';

/// Chat grup penghuni & pengelola (endpoint privat /chat).
class ChatService {
  ChatService(this._client);

  final ApiClient _client;

  /// Daftar grup milik penghuni + total pesan belum dibaca.
  Future<ChatRoomList> rooms() async {
    final json = await _client.get('/api/v1/chat/rooms') as Map<String, dynamic>;

    return ChatRoomList(
      rooms: (json['data'] as List<dynamic>)
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadTotal: (json['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  /// Pesan dalam satu grup (terbaru di akhir). [afterId] untuk
  /// polling ringan; [markRead] menandai pesan sudah dibaca.
  Future<List<Message>> messages(
    int roomId, {
    int? afterId,
    bool markRead = true,
  }) async {
    final json = await _client.get(
      '/api/v1/chat/rooms/$roomId/messages',
      query: {
        if (afterId != null) 'after_id': '$afterId',
        if (!markRead) 'mark_read': '0',
      },
    ) as Map<String, dynamic>;

    return (json['data'] as List<dynamic>)
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kirim pesan ke grup (penghuni; pengumuman hanya admin).
  Future<Message> send(int roomId, String body) async {
    final json = await _client.post('/api/v1/chat/rooms/$roomId/messages',
        body: {'body': body}) as Map<String, dynamic>;

    return Message.fromJson(json['data'] as Map<String, dynamic>);
  }
}

/// Ringkasan satu grup chat hasil dari API /chat/rooms.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.membersCount,
    required this.unreadCount,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
        membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        lastMessage: json['last_message'] == null
            ? null
            : LastMessage.fromJson(json['last_message'] as Map<String, dynamic>),
      );

  final int id;
  final String name;
  final String? description;
  final int membersCount;
  final int unreadCount;
  final LastMessage? lastMessage;
}

/// Pesan terakhir grup (untuk pratinjau daftar grup).
class LastMessage {
  const LastMessage({
    required this.body,
    required this.isAnnouncement,
    required this.senderName,
    required this.sentAtFormatted,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) => LastMessage(
        body: json['body'] as String? ?? '',
        isAnnouncement: json['is_announcement'] as bool? ?? false,
        senderName: json['sender_name'] as String?,
        sentAtFormatted: json['sent_at_formatted'] as String?,
      );

  final String body;
  final bool isAnnouncement;
  final String? senderName;
  final String? sentAtFormatted;
}

/// Hasil daftar grup + total belum dibaca.
class ChatRoomList {
  const ChatRoomList({required this.rooms, required this.unreadTotal});

  final List<ChatRoom> rooms;
  final int unreadTotal;
}

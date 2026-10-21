/// Satu pesan chat hasil dari API /chat/rooms/{id}/messages.
class Message {
  const Message({
    required this.id,
    required this.chatRoomId,
    required this.body,
    required this.isAnnouncement,
    this.sentAt,
    this.sentAtFormatted,
    required this.isOwn,
    this.senderId,
    this.senderName,
    this.senderRole,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: (json['id'] as num).toInt(),
        chatRoomId: (json['chat_room_id'] as num).toInt(),
        body: json['body'] as String,
        isAnnouncement: json['is_announcement'] as bool? ?? false,
        sentAt: json['sent_at'] as String?,
        sentAtFormatted: json['sent_at_formatted'] as String?,
        isOwn: json['is_own'] as bool? ?? false,
        senderId: (json['sender'] as Map<String, dynamic>?)?['id'] as num?,
        senderName:
            (json['sender'] as Map<String, dynamic>?)?['name'] as String?,
        senderRole:
            (json['sender'] as Map<String, dynamic>?)?['role'] as String?,
      );

  final int id;
  final int chatRoomId;
  final String body;
  final bool isAnnouncement;
  final String? sentAt;
  final String? sentAtFormatted;

  /// true bila pesan dikirim oleh pengguna yang login.
  final bool isOwn;
  final num? senderId;
  final String? senderName;
  final String? senderRole;
}

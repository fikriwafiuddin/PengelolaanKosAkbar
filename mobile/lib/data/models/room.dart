import 'dart:ui' show Color;

import 'facility.dart';

/// Status ketersediaan kamar.
enum RoomStatus { kosong, terisi, terbooking }

/// Data satu kamar kos hasil dari API /rooms.
class Room {
  const Room({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.priceMonthly,
    required this.status,
    required this.statusLabel,
    required this.description,
    required this.facilities,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: (json['id'] as num).toInt(),
        roomNumber: json['room_number'].toString(),
        type: json['type'] as String,
        priceMonthly: (json['price_monthly'] as num).toDouble(),
        status: RoomStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RoomStatus.kosong,
        ),
        statusLabel: json['status_label'] as String? ?? json['status'] as String,
        description: json['description'] as String?,
        facilities: (json['facilities'] as List<dynamic>? ?? [])
            .map((e) => Facility.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String roomNumber;
  final String type;
  final double priceMonthly;
  final RoomStatus status;
  final String statusLabel;
  final String? description;
  final List<Facility> facilities;

  /// "Kamar 12".
  String get title => 'Kamar $roomNumber';

  /// Pasangan warna badge status (foreground, background) mengikuti desain UI.
  (Color, Color) get statusColors {
    return switch (status) {
      RoomStatus.kosong => (const Color(0xFF0F766E), const Color(0xFFE0F2F1)),
      RoomStatus.terisi => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
      RoomStatus.terbooking => (const Color(0xFF6D28D9), const Color(0xFFEDE9FE)),
    };
  }
}

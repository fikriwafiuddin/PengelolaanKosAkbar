/// Profil identitas penghuni (relasi 1:1 dengan akun user).
class ResidentProfile {
  const ResidentProfile({
    required this.id,
    required this.fullName,
    required this.identityNumber,
    this.birthDate,
    this.address,
    this.occupation,
    this.room,
  });

  factory ResidentProfile.fromJson(Map<String, dynamic> json) {
    final roomJson = json['room'];

    return ResidentProfile(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      identityNumber: json['identity_number'] as String,
      birthDate: json['birth_date'] as String?,
      address: json['address'] as String?,
      occupation: json['occupation'] as String?,
      room: roomJson is Map<String, dynamic> ? RoomInfo.fromJson(roomJson) : null,
    );
  }

  final int id;
  final String fullName;
  final String identityNumber;
  final String? birthDate;
  final String? address;
  final String? occupation;
  final RoomInfo? room;
}

/// Ringkasan kamar yang sedang disewa (dari booking aktif).
class RoomInfo {
  const RoomInfo({
    required this.roomNumber,
    required this.type,
    this.startDate,
    this.durationMonths,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) => RoomInfo(
        roomNumber: json['room_number'].toString(),
        type: json['type'] as String,
        startDate: json['start_date'] as String?,
        durationMonths: json['duration_months'] as int?,
      );

  final String roomNumber;
  final String type;
  final String? startDate;
  final int? durationMonths;

  String get title => 'Kamar $roomNumber';
}

/// Akun user yang sedang login + profil penghuninya.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.resident,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        resident: json['resident'] is Map<String, dynamic>
            ? ResidentProfile.fromJson(json['resident'] as Map<String, dynamic>)
            : null,
      );

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final ResidentProfile? resident;

  /// Inisial nama untuk avatar (mis. "Dimas Pratama" -> "DP").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  bool get isAdmin => role == 'admin';
}

/// Fasilitas kamar (AC, WiFi, KM Dalam, ...).
class Facility {
  const Facility({required this.id, required this.name});

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );

  final int id;
  final String name;
}

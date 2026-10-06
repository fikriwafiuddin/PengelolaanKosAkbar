import '../api_client.dart';
import '../models/facility.dart';
import '../models/room.dart';

/// Hasil daftar kamar terpaginasi.
class RoomPage {
  const RoomPage({
    required this.rooms,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Room> rooms;
  final int currentPage;
  final int lastPage;
  final int total;
}

/// Katalog & pencarian kamar (endpoint publik).
class RoomService {
  RoomService(this._client);

  final ApiClient _client;

  /// Ambil daftar kamar dengan pencarian & filter.
  ///
  /// [query]  — kata kunci (nomor kamar / tipe / fasilitas)
  /// [type]   — tipe kamar, mis. "Lantai 1 - AC"
  /// [status] — kosong | terisi | terbooking
  /// [page]   — nomor halaman
  Future<RoomPage> list({
    String? query,
    String? type,
    String? status,
    int page = 1,
  }) async {
    final json = await _client.get('/api/v1/rooms', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
      'page': '$page',
    }) as Map<String, dynamic>;

    final meta = json['meta'] as Map<String, dynamic>;

    return RoomPage(
      rooms: (json['data'] as List<dynamic>)
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (meta['current_page'] as num).toInt(),
      lastPage: (meta['last_page'] as num).toInt(),
      total: (meta['total'] as num).toInt(),
    );
  }

  /// Detail satu kamar.
  Future<Room> detail(int id) async {
    final json = await _client.get('/api/v1/rooms/$id') as Map<String, dynamic>;

    return Room.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Daftar seluruh fasilitas (untuk filter).
  Future<List<Facility>> facilities() async {
    final json = await _client.get('/api/v1/facilities') as Map<String, dynamic>;

    return (json['data'] as List<dynamic>)
        .map((e) => Facility.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

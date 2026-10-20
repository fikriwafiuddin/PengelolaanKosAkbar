import '../api_client.dart';
import '../models/booking.dart';

/// Pemesanan kamar milik penghuni (endpoint privat /bookings).
class BookingService {
  BookingService(this._client);

  final ApiClient _client;

  /// Riwayat pemesanan penghuni yang login (terbaru duluan).
  Future<List<Booking>> myBookings() async {
    final json = await _client.get('/api/v1/bookings') as Map<String, dynamic>;

    return (json['data'] as List<dynamic>)
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Pesan kamar: pilih tanggal mulai + durasi sewa (bulan).
  Future<Booking> create({
    required int roomId,
    required DateTime startDate,
    required int durationMonths,
    String? note,
  }) async {
    final json = await _client.post('/api/v1/bookings', body: {
      'room_id': roomId,
      'start_date':
          '${startDate.year.toString().padLeft(4, '0')}-'
          '${startDate.month.toString().padLeft(2, '0')}-'
          '${startDate.day.toString().padLeft(2, '0')}',
      'duration_months': durationMonths,
      if (note != null && note.isNotEmpty) 'note': note,
    }) as Map<String, dynamic>;

    return Booking.fromJson(json['data'] as Map<String, dynamic>);
  }
}

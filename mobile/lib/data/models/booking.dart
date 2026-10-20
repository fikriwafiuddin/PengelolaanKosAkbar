import 'invoice.dart';

/// Status pemesanan kamar.
enum BookingStatus { menunggu, aktif, selesai, batal }

/// Data satu pemesanan kamar hasil dari API /bookings.
class Booking {
  const Booking({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.priceMonthly,
    required this.priceFormatted,
    required this.startDate,
    required this.durationMonths,
    required this.status,
    required this.statusLabel,
    this.note,
    required this.invoices,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: (json['id'] as num).toInt(),
        roomNumber:
            ((json['room'] as Map<String, dynamic>?)?['room_number'] as String?)
                ?? '-',
        roomType:
            ((json['room'] as Map<String, dynamic>?)?['type'] as String?) ?? '-',
        priceMonthly:
            (((json['room'] as Map<String, dynamic>?)?['price_monthly'] as num?)
                    ?.toDouble()) ??
            0,
        priceFormatted:
            ((json['room'] as Map<String, dynamic>?)?['price_formatted']
                    as String?) ??
            '-',
        startDate: DateTime.tryParse(json['start_date'] as String? ?? '') ??
            DateTime(2000),
        durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
        status: switch (json['status']) {
          'menunggu' => BookingStatus.menunggu,
          'selesai' => BookingStatus.selesai,
          'batal' => BookingStatus.batal,
          _ => BookingStatus.aktif,
        },
        statusLabel: json['status_label'] as String? ?? json['status'] as String,
        note: json['note'] as String?,
        invoices: (json['invoices'] as List<dynamic>? ?? [])
            .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String roomNumber;
  final String roomType;
  final double priceMonthly;
  final String priceFormatted;
  final DateTime startDate;
  final int durationMonths;
  final BookingStatus status;
  final String statusLabel;
  final String? note;
  final List<Invoice> invoices;
}

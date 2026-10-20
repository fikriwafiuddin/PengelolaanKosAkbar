import 'payment.dart';

/// Status tagihan sewa bulanan.
enum InvoiceStatus { belumBayar, lunas }

/// Data satu tagihan sewa hasil dari API /invoices.
class Invoice {
  const Invoice({
    required this.id,
    required this.bookingId,
    required this.period,
    required this.periodLabel,
    required this.amount,
    required this.amountFormatted,
    required this.dueDate,
    required this.dueDateFormatted,
    required this.status,
    required this.statusLabel,
    required this.isOverdue,
    required this.roomNumber,
    required this.roomType,
    required this.payments,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: (json['id'] as num).toInt(),
        bookingId: (json['booking_id'] as num).toInt(),
        period: json['period'] as String,
        periodLabel: json['period_label'] as String? ?? json['period'] as String,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountFormatted:
            json['amount_formatted'] as String? ?? '${json['amount']}',
        dueDate: DateTime.tryParse(json['due_date'] as String? ?? '') ??
            DateTime(2000),
        dueDateFormatted:
            json['due_date_formatted'] as String? ?? (json['due_date'] ?? '-'),
        status: json['status'] == 'lunas'
            ? InvoiceStatus.lunas
            : InvoiceStatus.belumBayar,
        statusLabel: json['status_label'] as String? ?? json['status'] as String,
        isOverdue: json['is_overdue'] as bool? ?? false,
        roomNumber: ((json['room'] as Map<String, dynamic>?)?['room_number']
                as String?) ??
            '-',
        roomType:
            ((json['room'] as Map<String, dynamic>?)?['type'] as String?) ??
            '-',
        payments: (json['payments'] as List<dynamic>? ?? [])
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final int bookingId;
  final String period;

  /// "Oktober 2026".
  final String periodLabel;
  final double amount;
  final String amountFormatted;
  final DateTime dueDate;
  final String dueDateFormatted;
  final InvoiceStatus status;
  final String statusLabel;
  final bool isOverdue;
  final String roomNumber;
  final String roomType;
  final List<Payment> payments;

  /// Masih menunggu verifikasi admin (tidak boleh kirim bayar lagi).
  bool get hasPendingPayment =>
      payments.any((payment) => payment.status == PaymentStatus.pending);
}

/// Ringkasan total tagihan penghuni.
class InvoiceSummary {
  const InvoiceSummary({
    required this.invoices,
    required this.totalCount,
    required this.totalAmount,
    required this.unpaidCount,
    required this.unpaidAmount,
    required this.nextDueDate,
  });

  final List<Invoice> invoices;
  final int totalCount;
  final double totalAmount;
  final int unpaidCount;
  final double unpaidAmount;
  final DateTime? nextDueDate;
}

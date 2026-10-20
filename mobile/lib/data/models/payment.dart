/// Status verifikasi pembayaran.
enum PaymentStatus { pending, terverifikasi, ditolak }

/// Metode pembayaran sewa.
enum PaymentMethod { transfer, tunai }

/// Data satu pembayaran ( hasil dari API /invoices/{id}/payments).
class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.amountFormatted,
    required this.method,
    required this.methodLabel,
    this.proofUrl,
    this.receiptNo,
    required this.status,
    required this.statusLabel,
    this.paidAtFormatted,
    this.verifiedAtFormatted,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: (json['id'] as num).toInt(),
        invoiceId: (json['invoice_id'] as num).toInt(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        amountFormatted:
            json['amount_formatted'] as String? ?? '${json['amount']}',
        method: json['method'] == 'tunai'
            ? PaymentMethod.tunai
            : PaymentMethod.transfer,
        methodLabel: json['method_label'] as String? ?? json['method'] as String,
        proofUrl: json['proof_url'] as String?,
        receiptNo: json['receipt_no'] as String?,
        status: switch (json['status']) {
          'terverifikasi' => PaymentStatus.terverifikasi,
          'ditolak' => PaymentStatus.ditolak,
          _ => PaymentStatus.pending,
        },
        statusLabel: json['status_label'] as String? ?? json['status'] as String,
        paidAtFormatted: json['paid_at_formatted'] as String?,
        verifiedAtFormatted: json['verified_at_formatted'] as String?,
      );

  final int id;
  final int invoiceId;
  final double amount;
  final String amountFormatted;
  final PaymentMethod method;
  final String methodLabel;

  /// URL relatif bukti bayar (/storage/payments/xxx.png).
  final String? proofUrl;

  /// Nomor kuitansi (terisi setelah diverifikasi admin).
  final String? receiptNo;
  final PaymentStatus status;
  final String statusLabel;
  final String? paidAtFormatted;
  final String? verifiedAtFormatted;
}

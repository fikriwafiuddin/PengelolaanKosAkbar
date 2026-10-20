import '../api_client.dart';
import '../models/payment.dart';

/// Pengiriman pembayaran sewa (endpoint privat
/// /invoices/{id}/payments).
class PaymentService {
  PaymentService(this._client);

  final ApiClient _client;

  /// Kirim pembayaran: nominal + metode + bukti transfer (wajib
  /// bila metode transfer). [proofPath] adalah path berkas lokal
  /// hasil image_picker.
  Future<Payment> submit({
    required int invoiceId,
    required double amount,
    required PaymentMethod method,
    String? proofPath,
  }) async {
    final json = await _client.postMultipart(
      '/api/v1/invoices/$invoiceId/payments',
      fields: {
        'amount': amount == amount.roundToDouble()
            ? amount.toInt().toString()
            : amount.toString(),
        'method': method.name,
      },
      fileField: proofPath != null ? 'proof' : null,
      filePath: proofPath,
    ) as Map<String, dynamic>;

    return Payment.fromJson(json['data'] as Map<String, dynamic>);
  }
}

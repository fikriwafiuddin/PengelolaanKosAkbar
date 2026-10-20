import '../api_client.dart';
import '../models/invoice.dart';

/// Tagihan sewa bulanan milik penghuni (endpoint privat /invoices).
class InvoiceService {
  InvoiceService(this._client);

  final ApiClient _client;

  /// Seluruh tagihan + ringkasan total (rincian & total tagihan sewa).
  Future<InvoiceSummary> myInvoices() async {
    final json = await _client.get('/api/v1/invoices') as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    return InvoiceSummary(
      invoices: (json['data'] as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (summary['total_count'] as num?)?.toInt() ?? 0,
      totalAmount: (summary['total_amount'] as num?)?.toDouble() ?? 0,
      unpaidCount: (summary['unpaid_count'] as num?)?.toInt() ?? 0,
      unpaidAmount: (summary['unpaid_amount'] as num?)?.toDouble() ?? 0,
      nextDueDate:
          DateTime.tryParse(summary['next_due_date'] as String? ?? ''),
    );
  }

  /// Detail satu tagihan beserta riwayat pembayarannya.
  Future<Invoice> detail(int id) async {
    final json =
        await _client.get('/api/v1/invoices/$id') as Map<String, dynamic>;

    return Invoice.fromJson(json['data'] as Map<String, dynamic>);
  }
}

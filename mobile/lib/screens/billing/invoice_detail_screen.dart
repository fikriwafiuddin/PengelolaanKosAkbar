import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../data/api_client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/payment.dart';
import '../../data/services/invoice_service.dart';
import '../../theme/app_theme.dart';
import 'payment_form_screen.dart';

/// Rincian satu tagihan sewa + riwayat pembayarannya; titik masuk
/// pengiriman pembayaran (input nominal & unggah bukti).
class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late final InvoiceService _invoices;
  Invoice? _invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invoices = InvoiceService(context.read<ApiClient>());
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _error = null);

    try {
      final invoice = await _invoices.detail(widget.invoiceId);
      setState(() => _invoice = invoice);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Buka form pembayaran lalu muat ulang tagihan setelah selesai.
  Future<void> _openPaymentForm() async {
    final invoice = _invoice;
    if (invoice == null) return;

    final paid = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => PaymentFormScreen(invoice: invoice),
    ));

    if (paid == true) {
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;

    return Scaffold(
      appBar: AppBar(title: Text(invoice?.periodLabel ?? 'Rincian Tagihan')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.terracotta))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            style:
                                const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: _fetch, child: const Text('Coba Lagi')),
                      ],
                    ),
                  )
                : invoice == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        children: [
                          _DetailCard(invoice: invoice),
                          const SizedBox(height: 16),
                          _PaymentsCard(
                            invoice: invoice,
                            onRetryAfterReject: _openPaymentForm,
                          ),
                          const SizedBox(height: 24),

                          // Aksi bayar
                          if (invoice.status == InvoiceStatus.belumBayar &&
                              !invoice.hasPendingPayment)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.terracotta,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _openPaymentForm,
                                icon: const Icon(Icons.payment_rounded),
                                label: const Text(
                                  'Bayar Sekarang',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            )
                          else if (invoice.hasPendingPayment)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded,
                                      color: Color(0xFFB45309), size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Pembayaran Anda menunggu verifikasi pengelola.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
      ),
    );
  }
}

/// Kartu rincian tagihan: kamar, periode, nominal, jatuh tempo, status.
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = invoice.isOverdue
        ? (const Color(0xFFB91C1C), const Color(0xFFFEE2E2))
        : switch (invoice.status) {
            InvoiceStatus.lunas => (const Color(0xFF0F766E), const Color(0xFFE0F2F1)),
            InvoiceStatus.belumBayar =>
              (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
          };

    final rows = <(String, String)>[
      ('Kamar', 'Kamar ${invoice.roomNumber} (${invoice.roomType})'),
      ('Periode Sewa', invoice.periodLabel),
      ('Jatuh Tempo', invoice.dueDateFormatted),
      ('Status', invoice.isOverdue ? 'Terlambat' : invoice.statusLabel),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RINCIAN TAGIHAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    invoice.isOverdue ? 'Terlambat' : invoice.statusLabel,
                    style: TextStyle(
                        color: fg,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            const Text(
              'TOTAL TAGIHAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.amountFormatted,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Riwayat pembayaran tagihan ini (status verifikasi + kuitansi).
class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.invoice, this.onRetryAfterReject});

  final Invoice invoice;
  final VoidCallback? onRetryAfterReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RIWAYAT PEMBAYARAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (invoice.payments.isEmpty)
              const Text('Belum ada pembayaran untuk tagihan ini.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13))
            else
              for (final payment in invoice.payments)
                _PaymentTile(payment: payment),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (payment.status) {
      PaymentStatus.terverifikasi => (const Color(0xFF0F766E), const Color(0xFFE0F2F1)),
      PaymentStatus.ditolak => (const Color(0xFFB91C1C), const Color(0xFFFEE2E2)),
      PaymentStatus.pending => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    };

    final proofUrl = ApiConfig.resolveImageUrl(payment.proofUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Thumbnail bukti bayar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: proofUrl != null
                ? Image.network(
                    proofUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                        size: 20),
                  )
                : const Icon(Icons.payments_outlined,
                    color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.methodLabel} · ${payment.amountFormatted}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.paidAtFormatted ?? '-',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
                if (payment.receiptNo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Kuitansi ${payment.receiptNo}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              payment.statusLabel,
              style: TextStyle(
                  color: fg, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

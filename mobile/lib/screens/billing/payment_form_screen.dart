import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/invoice.dart';
import '../../data/models/payment.dart';
import '../../data/services/payment_service.dart';
import '../../theme/app_theme.dart';

/// Form kirim pembayaran sewa: input nominal, pilih metode
/// (transfer/tunai), dan unggah bukti bayar (wajib untuk transfer).
class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key, required this.invoice});

  final Invoice invoice;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late final PaymentService _payments;
  late final TextEditingController _amountController;
  PaymentMethod _method = PaymentMethod.transfer;
  String? _proofPath;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _payments = PaymentService(context.read<ApiClient>());
    // Nominal langsung terisi penuh sesuai total tagihan.
    _amountController = TextEditingController(
      text: widget.invoice.amount == widget.invoice.amount.roundToDouble()
          ? widget.invoice.amount.toInt().toString()
          : widget.invoice.amount.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _proofPath = picked.path);
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (amount == null || amount < 1000) {
      _showError('Nominal pembayaran minimal Rp 1.000.');
      return;
    }

    if (amount > widget.invoice.amount) {
      _showError('Nominal tidak boleh melebihi total tagihan '
          '(${widget.invoice.amountFormatted}).');
      return;
    }

    if (_method == PaymentMethod.transfer && _proofPath == null) {
      _showError('Bukti transfer wajib diunggah untuk pembayaran transfer.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await _payments.submit(
        invoiceId: widget.invoice.id,
        amount: amount,
        method: _method,
        proofPath: _proofPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran terkirim. Menunggu verifikasi pengelola.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showError(e.errors.values.expand((messages) => messages).firstOrNull ??
          e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.terracotta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar Tagihan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Ringkasan tagihan yang dibayar
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppColors.terracotta),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kamar ${invoice.roomNumber} · ${invoice.periodLabel}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          Text(
                            'Total tagihan ${invoice.amountFormatted}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nominal pembayaran
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOMINAL PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: AppColors.field,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metode pembayaran
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'METODE PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RadioGroup<PaymentMethod>(
                      groupValue: _method,
                      onChanged: (value) =>
                          setState(() => _method = value ?? _method),
                      child: Column(
                        children: [
                          for (final method in PaymentMethod.values)
                            RadioListTile<PaymentMethod>(
                              value: method,
                              title: Text(
                                method == PaymentMethod.transfer
                                    ? 'Transfer Bank'
                                    : 'Tunai (ke pengelola)',
                                style: const TextStyle(
                                    fontSize: 13.5, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                method == PaymentMethod.transfer
                                    ? 'Unggah bukti transfer sebagai lampiran'
                                    : 'Tanpa bukti unggahan',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              activeColor: AppColors.terracotta,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bukti bayar (wajib untuk transfer)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'BUKTI PEMBAYARAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (_method == PaymentMethod.transfer)
                          const Text('*wajib',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.terracotta,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_proofPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_proofPath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.field,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.teal,
                                size: 36),
                          ),
                        ),
                      ),
                    if (_proofPath != null) const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickProof,
                            icon: const Icon(Icons.attach_file_rounded, size: 18),
                            label: Text(
                              _proofPath == null
                                  ? 'Pilih Gambar Bukti'
                                  : 'Ganti Gambar',
                            ),
                          ),
                        ),
                        if (_proofPath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Hapus bukti',
                            onPressed: () => setState(() => _proofPath = null),
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.terracotta),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text(
                  'Kirim Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

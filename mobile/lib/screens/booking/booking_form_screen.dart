import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/room.dart';
import '../../data/services/booking_service.dart';
import '../../theme/app_theme.dart';

/// Form pemesanan kamar: pilih tanggal mulai sewa + durasi (bulan),
/// lengkap dengan rincian total sebelum konfirmasi (Sprint 2 —
// aktivitas "Pesan Kamar" pada activity diagram).
class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.room});

  final Room room;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  late final BookingService _bookings;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  int _durationMonths = 3;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _bookings = BookingService(context.read<ApiClient>());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih tanggal mulai sewa',
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Pemesanan'),
        content: Text(
          'Pesan ${widget.room.title} mulai '
          '${DateFormat('d MMMM yyyy', 'id_ID').format(_startDate)} '
          'selama $_durationMonths bulan?\n\n'
          'Tagihan sewa bulanan akan langsung dibuat setelah konfirmasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.terracotta),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya, Pesan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);

    try {
      await _bookings.create(
        roomId: widget.room.id,
        startDate: _startDate,
        durationMonths: _durationMonths,
        note: _noteController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${widget.room.title} berhasil dipesan. Tagihan tersedia di tab Tagihan.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e.errors.values.expand((messages) => messages).firstOrNull ??
                  e.message),
          backgroundColor: AppColors.terracotta,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rupiah =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final total = widget.room.priceMonthly * _durationMonths;

    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Kamar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Ringkasan kamar
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.field,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bed_rounded,
                          color: AppColors.terracotta, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.room.title} · ${widget.room.type}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          Text(
                            '${rupiah.format(widget.room.priceMonthly)} / bulan',
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

            // Tanggal mulai + durasi
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RENCANA SEWA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.field,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined,
                                size: 20, color: AppColors.terracotta),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('d MMMM yyyy', 'id_ID')
                                    .format(_startDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark),
                              ),
                            ),
                            const Text('Tanggal Mulai',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: _durationMonths,
                      decoration: InputDecoration(
                        labelText: 'Durasi Sewa',
                        filled: true,
                        fillColor: AppColors.field,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        for (var month = 1; month <= 12; month++)
                          DropdownMenuItem(
                            value: month,
                            child: Text('$month bulan'),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _durationMonths = value ?? 1),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        filled: true,
                        fillColor: AppColors.field,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rincian total
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFFBF3EC),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga per bulan',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        Text(rupiah.format(widget.room.priceMonthly),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durasi',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        Text('$_durationMonths bulan',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ],
                    ),
                    const Divider(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Sewa',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark),
                        ),
                        Text(
                          rupiah.format(total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ditagihkan bulanan sesuai harga kamar; jatuh tempo tiap tanggal 25.',
                      style:
                          TextStyle(fontSize: 11.5, color: AppColors.textMuted),
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
                    : const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Konfirmasi Pemesanan',
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

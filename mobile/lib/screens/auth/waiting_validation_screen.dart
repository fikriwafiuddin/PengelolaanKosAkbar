import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Halaman setelah registrasi berhasil: akun menunggu validasi admin.
/// Pengguna belum bisa login sampai admin menyetujui akunnya.
class WaitingValidationScreen extends StatelessWidget {
  const WaitingValidationScreen({super.key, this.fullName});

  /// Nama pendaftar (untuk sapaan), bila ada.
  final String? fullName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 42,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Registrasi Berhasil!',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName != null
                      ? 'Terima kasih, ${fullName!.split(' ').first}! Akun Anda sedang menunggu validasi admin.'
                      : 'Akun Anda sedang menunggu validasi admin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Anda dapat masuk menggunakan akun ini setelah pengelola kos menyetujui pendaftaran Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Kembali ke Halaman Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import 'splash_screen.dart';

/// Gerbang autentikasi — satu-satunya titik memilih halaman awal
/// berdasarkan status sesi:
///
/// - [AuthStatus.loading]    → SplashScreen (bootstrap sedang berjalan)
/// - [AuthStatus.loggedOut]  → LoginScreen
/// - [AuthStatus.loggedIn]   → MainShell (Beranda/Tagihan/Chat/Profil)
///
/// Perpindahan antar halaman terjadi otomatis reaktif terhadap
/// AuthProvider, sehingga tidak perlu navigasi manual setelah
/// login/registrasi/logout berhasil.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();

    // Muat token tersimpan + validasi ke server sekali saat aplikasi dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.loading => const SplashScreen(),
      AuthStatus.loggedOut => const LoginScreen(),
      AuthStatus.loggedIn => const MainShell(),
    };
  }
}

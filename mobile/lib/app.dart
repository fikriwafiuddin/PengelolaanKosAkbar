import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Root aplikasi: penyedia state + rute bernama.
class KostAkbarApp extends StatelessWidget {
  const KostAkbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kost Akbar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const MainShell(),
      },
      builder: (context, child) {
        // Reaksi terhadap perubahan status autentikasi:
        // splash -> login / beranda.
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.status == AuthStatus.loading) {
              return const SplashScreen();
            }

            // Child (hasil Navigator) hanya dipakai saat sudah login;
            // untuk status loggedOut kita render halaman login langsung
            // agar tidak bisa "kembali" ke halaman dalam sesi lama.
            if (auth.status == AuthStatus.loggedOut) {
              return const LoginScreen();
            }

            return child ?? const MainShell();
          },
        );
      },
    );
  }
}

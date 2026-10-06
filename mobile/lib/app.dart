import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

/// Root aplikasi: tema + gerbang autentikasi.
class KostAkbarApp extends StatelessWidget {
  const KostAkbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kost Akbar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

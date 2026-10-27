import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/firebase_config.dart';
import 'data/api_client.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Simbol tanggal lokal (id_ID) untuk DateFormat di seluruh aplikasi.
  initializeDateFormatting('id_ID');

  // Firebase opsional: hanya diinisialisasi bila dikonfigurasi
  // (lihat config/firebase_config.dart). Tanpa konfigurasi, seluruh
  // fitur memakai fallback polling + notifikasi database.
  if (kFirebaseOptions != null) {
    await Firebase.initializeApp(options: kFirebaseOptions);
  }

  runApp(const KostAkbarMobile());
}

/// Entry point: memasang ApiClient + AuthProvider secara global.
class KostAkbarMobile extends StatelessWidget {
  const KostAkbarMobile({super.key, this.apiClient});

  /// Klien API injeksi (untuk pengujian); null = klien HTTP sungguhan.
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => apiClient ?? ApiClient()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<ApiClient>()),
        ),
      ],
      child: const KostAkbarApp(),
    );
  }
}

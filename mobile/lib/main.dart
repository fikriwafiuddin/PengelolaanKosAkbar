import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/api_client.dart';
import 'providers/auth_provider.dart';

void main() {
  // Simbol tanggal lokal (id_ID) untuk DateFormat di seluruh aplikasi.
  initializeDateFormatting('id_ID');

  runApp(const KostAkbarMobile());
}

/// Entry point: memasang ApiClient + AuthProvider secara global.
class KostAkbarMobile extends StatelessWidget {
  const KostAkbarMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<ApiClient>()),
        ),
      ],
      child: const KostAkbarApp(),
    );
  }
}

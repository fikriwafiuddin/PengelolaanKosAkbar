import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kost_akbar/data/api_client.dart';
import 'package:kost_akbar/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bentuk user standar dari API.
Map<String, dynamic> _userJson({bool withRoom = false}) => {
      'id': 2,
      'name': 'Dimas Pratama',
      'email': 'dimaspratama@kostakbar.id',
      'role': 'penghuni',
      'phone': '+628123000000',
      'resident': {
        'id': 1,
        'full_name': 'Dimas Pratama',
        'identity_number': '357300000000000000',
        'birth_date': '2006-10-01',
        'address': 'Kota Kediri',
        'occupation': 'Mahasiswa',
        if (withRoom)
          'room': {
            'room_number': '1',
            'type': 'Lantai 1 - AC',
            'start_date': '2026-04-01',
            'duration_months': 12,
          },
      },
    };

/// Mock API: login/me/rooms semuanya sukses.
http.Client _mockApi() => MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/v1/auth/login' && request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'message': 'Login berhasil.',
            'data': {'user': _userJson(), 'token': 'token-uji'},
          }),
          200,
        );
      }

      if (path == '/api/v1/auth/me') {
        return http.Response(
          jsonEncode({'data': _userJson(withRoom: true)}),
          200,
        );
      }

      if (path == '/api/v1/rooms') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 1,
                'room_number': '7',
                'type': 'Lantai 1 - AC',
                'price_monthly': 600000,
                'price_formatted': 'Rp 600.000',
                'status': 'kosong',
                'status_label': 'Tersedia',
                'description': 'Kamar nyaman.',
                'facilities': [
                  {'id': 1, 'name': 'AC'},
                  {'id': 4, 'name': 'WiFi'},
                ],
              },
            ],
            'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
          }),
          200,
        );
      }

      return http.Response(jsonEncode({'message': 'not found'}), 404);
    });

void main() {
  // Plugin storage perlu mock agar bisa berjalan di lingkungan test.
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash tampil saat bootstrap', (tester) async {
    await tester.pumpWidget(const KostAkbarMobile());

    expect(find.text('KOST AKBAR'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Tanpa token tersimpan -> diarahkan ke halaman login',
      (tester) async {
    await tester.pumpWidget(const KostAkbarMobile());
    await tester.pumpAndSettle();

    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });

  testWidgets(
      'Login sukses -> tiba di Beranda (regresi: spinner tidak menetap)',
      (tester) async {
    await tester.pumpWidget(
      KostAkbarMobile(apiClient: ApiClient(client: _mockApi())),
    );
    await tester.pumpAndSettle();

    // Isi formulir login lalu kirim.
    await tester.enterText(
      find.byType(TextFormField).first,
      'dimaspratama@kostakbar.id',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();

    // Wajib tiba di MainShell, bukan splash berputar selamanya.
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

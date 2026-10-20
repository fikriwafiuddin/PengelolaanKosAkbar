import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
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

      if (path == '/api/v1/auth/register' && request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'message':
                'Registrasi berhasil. Akun Anda menunggu validasi admin.',
            'data': {'user': _userJson()},
          }),
          201,
        );
      }

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

      if (path == '/api/v1/auth/profile' && request.method == 'PUT') {
        return http.Response(
          jsonEncode({
            'message': 'Profil berhasil diperbarui.',
            'data': _userJson(withRoom: true),
          }),
          200,
        );
      }

      if (path == '/api/v1/invoices') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 54,
                'booking_id': 17,
                'period': '2026-10',
                'period_label': 'Oktober 2026',
                'amount': 450000,
                'amount_formatted': 'Rp 450.000',
                'due_date': '2026-10-25',
                'due_date_formatted': '25 Oktober 2026',
                'status': 'belum_bayar',
                'status_label': 'Belum Bayar',
                'is_overdue': false,
                'room': {'id': 24, 'room_number': '24', 'type': 'Lantai 3 - Reguler'},
                'payments': [],
              },
            ],
            'summary': {
              'total_count': 3,
              'total_amount': 1350000,
              'unpaid_count': 1,
              'unpaid_amount': 450000,
              'next_due_date': '2026-10-25T00:00:00.000000Z',
            },
          }),
          200,
        );
      }

      if (path == '/api/v1/invoices/54') {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 54,
              'booking_id': 17,
              'period': '2026-10',
              'period_label': 'Oktober 2026',
              'amount': 450000,
              'amount_formatted': 'Rp 450.000',
              'due_date': '2026-10-25',
              'due_date_formatted': '25 Oktober 2026',
              'status': 'belum_bayar',
              'status_label': 'Belum Bayar',
              'is_overdue': false,
              'room': {'id': 24, 'room_number': '24', 'type': 'Lantai 3 - Reguler'},
              'payments': [],
            },
          }),
          200,
        );
      }

      if (path == '/api/v1/notifications') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'notif-1',
                'title': 'Pengingat jatuh tempo tagihan sewa',
                'body':
                    'Tagihan sewa Kamar 24 periode Oktober 2026 jatuh tempo pada 25 Oktober 2026.',
                'invoice_id': 54,
                'room_number': '24',
                'read_at': null,
                'created_at': '2026-10-20T08:00:00.000000Z',
              },
            ],
            'unread_count': 1,
          }),
          200,
        );
      }

      if (path == '/api/v1/notifications/mark-read' && request.method == 'POST') {
        return http.Response(jsonEncode({'data': {'marked': 1}}), 200);
      }

      return http.Response(jsonEncode({'message': 'not found'}), 404);
    });

void main() {
  // Simbol tanggal id_ID (panggilan main() tidak berjalan saat test).
  setUpAll(() {
    initializeDateFormatting('id_ID');
  });

  // Plugin storage perlu mock agar bisa berjalan di lingkungan test.
  // Reset per-test supaya token yang tersimpan test sebelumnya tidak bocor.
  setUp(() {
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

  testWidgets(
      'Registrasi sukses -> halaman menunggu validasi (tanpa login otomatis)',
      (tester) async {
    // Formulir registrasi panjang — perbesar viewport agar semua
    // field terbangun (ListView membangun anak secara malas).
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      KostAkbarMobile(apiClient: ApiClient(client: _mockApi())),
    );
    await tester.pumpAndSettle();

    // Buka halaman registrasi dari tautan login (pastikan terlihat dulu).
    final registerLink = find.text('Daftar di sini');
    await tester.ensureVisible(registerLink);
    await tester.pumpAndSettle();
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    // Isi formulir registrasi (urutan field mengikuti layar;
    // tanggal lahir index 6 diisi lewat dialog date picker).
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'cahyo@contoh.com');
    await tester.enterText(fields.at(1), 'rahasia123');
    await tester.enterText(fields.at(2), 'rahasia123');
    await tester.enterText(fields.at(3), 'Cahyo Nugroho');
    await tester.enterText(fields.at(4), '3573123456780001');
    await tester.enterText(fields.at(5), '+6289911122233');

    await tester.tap(fields.at(6)); // tanggal lahir -> date picker
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // terima tanggal awal (usia >= 18)
    await tester.pumpAndSettle();

    await tester.enterText(fields.at(7), 'Mahasiswa');
    await tester.enterText(fields.at(8), 'Kediri');
    await tester.enterText(fields.at(9), 'Bapak Cahyo');
    await tester.enterText(fields.at(10), '+6281355550000');

    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();

    // Harus tiba di halaman menunggu validasi — bukan Beranda.
    expect(find.text('Registrasi Berhasil!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Tagihan: ringkasan, rincian & validasi bayar (Sprint 2)',
      (tester) async {
    // Layar tagihan memuat ringkasan + daftar — perlu viewport tinggi.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      KostAkbarMobile(apiClient: ApiClient(client: _mockApi())),
    );
    await tester.pumpAndSettle();

    // Login dulu sebagai penghuni.
    await tester.enterText(
      find.byType(TextFormField).first,
      'dimaspratama@kostakbar.id',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();

    // Pindah ke tab Tagihan (ikon receipt di bottom nav).
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();

    // Ringkasan total belum dibayar + baris tagihan.
    expect(find.text('TOTAL TAGIHAN BELUM DIBAYAR'), findsOneWidget);
    // Nominal muncul di kartu ringkasan dan di baris tagihan.
    expect(find.text('Rp 450.000'), findsNWidgets(2));
    expect(find.text('Kamar 24 · Oktober 2026'), findsOneWidget);
    expect(find.text('1 tagihan menunggu dibayar'), findsOneWidget);

    // Buka rincian tagihan.
    await tester.tap(find.text('Kamar 24 · Oktober 2026'));
    await tester.pumpAndSettle();
    expect(find.text('RINCIAN TAGIHAN'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);

    // Buka form pembayaran lalu kirim tanpa bukti (transfer) —
    // harus ditolak validasi lokal sebelum memanggil API.
    await tester.tap(find.text('Bayar Sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('NOMINAL PEMBAYARAN'), findsOneWidget);
    expect(find.text('Kirim Pembayaran'), findsOneWidget);

    await tester.tap(find.text('Kirim Pembayaran'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bukti transfer wajib diunggah untuk pembayaran transfer.'),
      findsOneWidget,
    );
  });
}

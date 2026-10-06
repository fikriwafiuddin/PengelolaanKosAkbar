import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kost_akbar/main.dart';

void main() {
  testWidgets('Aplikasi ter-build & splash Kost Akbar tampil', (tester) async {
    await tester.pumpWidget(const KostAkbarMobile());

    expect(find.text('KOST AKBAR'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

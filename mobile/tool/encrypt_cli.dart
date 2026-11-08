// CLI enkripsi PII — dipakai pengujian end-to-end (web/tests/
// pii_encryption_test.py) untuk mensimulasikan kripto aplikasi
// mobile secara NYATA (Dart pointycastle, bukan tiruan PHP):
//
//   dart run tool/encrypt_cli.dart <public_key_der_base64> <json_field>
//
// Contoh:
//   dart run tool/encrypt_cli.py ... '{"phone":"+628123"}'
//
// Mencetak JSON map field -> nilai tersegel PII1:...
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kost_akbar/data/pii_crypto.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Pemakaian: dart run tool/encrypt_cli.dart '
        '<public_key_der_base64> <json_field>');
    exit(64);
  }

  final publicKeyDer = base64Decode(args[0]);
  final fields = jsonDecode(args[1]) as Map<String, dynamic>;

  final sealed = <String, String>{};
  fields.forEach((field, value) {
    final text = value?.toString() ?? '';
    sealed[field] =
        text.isEmpty ? text : sealPii(text, Uint8List.fromList(publicKeyDer));
  });

  stdout.write(jsonEncode(sealed));
}

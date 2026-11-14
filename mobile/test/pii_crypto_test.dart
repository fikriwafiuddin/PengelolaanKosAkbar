import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kost_akbar/data/pii_crypto.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Bangun pasangan kunci RSA uji dengan seed aman (registry
/// pointycastle tidak menyediakan SecureRandom default).
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateKeyPair() {
  final random = math.Random.secure();
  final seeds =
      Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));

  final secureRandom = FortunaRandom()..seed(KeyParameter(seeds));

  final generator = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 1024, 64),
      secureRandom,
    ));

  return generator.generateKeyPair();
}

void main() {
  test('sealPii/openPii putaran kembali penuh', () {
    // Kunci 1024-bit cukup untuk uji (muat keymat 44 byte; produksi
    // memakai 2048) — pembangkitan lebih cepat di lingkungan test.
    final pair = _generateKeyPair();

    final der = spkiDer(pair.publicKey);
    final plain = '3573123456780001 — Jl. Mastrip No.130, Kediri';

    final sealed = sealPii(plain, der);

    // Format sesuai spesifikasi backend.
    expect(sealed.startsWith('PII1:'), isTrue);
    expect(sealed.substring('PII1:'.length).split('.'), hasLength(2));

    // Dapat dibuka kembali dengan kunci privat (tag GCM terverifikasi).
    expect(openPii(sealed, pair.privateKey), plain);
  });

  test('segel unik per panggilan (nonce/kunci sesi acak)', () {
    final der = spkiDer(_generateKeyPair().publicKey);

    final first = sealPii('nilai-sama', der);
    final second = sealPii('nilai-sama', der);

    expect(first == second, isFalse, reason: 'ciphertext harus berbeda');
  });
}

/// Bangun DER SPKI dari modulus+eksponen (mirror keluaran OpenSSL).
Uint8List spkiDer(RSAPublicKey key) {
  final algorithmId = ASN1Sequence()
    ..add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1])) // rsaEncryption
    ..add(ASN1Null());

  final rsaSequence = ASN1Sequence()
    ..add(ASN1Integer(key.modulus!))
    ..add(ASN1Integer(key.exponent!));

  final spki = ASN1Sequence()
    ..add(algorithmId)
    ..add(ASN1BitString(stringValues: rsaSequence.encode().toList()));

  return spki.encode();
}

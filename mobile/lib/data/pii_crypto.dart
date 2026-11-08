/// Kriptografi murni untuk enkripsi data pribadi (PII) — tanpa
/// dependensi Flutter sehingga bisa dipakai aplikasi maupun skrip
/// uji (tool/encrypt_cli.dart).
///
/// Format nilai tersegel (spesifikasi bersama backend):
///
///     PII1:<base64(RSA-OAEP-SHA1(kunciAES32+nonce12))>.<base64(ct||tag)>
///
/// RSA-OAEP memakai SHA-1 (default PHP openssl) agar kompatibel
/// dengan dekripsi backend memakai kunci privat di .env.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Prefix penanda nilai terenkripsi (sama dengan backend).
const String kPiiMarker = 'PII1:';

/// Segel satu nilai dengan kunci publik RSA (DER SPKI).
String sealPii(String plainText, Uint8List publicKeyDer) {
  final random = math.Random.secure();

  // Kunci sesi AES-256 (32 byte) + nonce GCM (12 byte).
  final keyBytes = _randomBytes(32, random);
  final nonce = _randomBytes(12, random);

  // 1. Enkripsi nilai dengan AES-256-GCM: ciphertext diikuti tag
  //    128-bit (doFinal-lah yang menulis tag & blok terakhir).
  final plainBytes = Uint8List.fromList(utf8.encode(plainText));
  final gcm = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(KeyParameter(keyBytes), 128, nonce, Uint8List(0)));
  final out = Uint8List(plainBytes.length + 16);
  final processed = gcm.processBytes(plainBytes, 0, plainBytes.length, out, 0);
  final flushed = gcm.doFinal(out, processed);
  final payload = out.sublist(0, processed + flushed);

  // 2. Bungkus kunci sesi dengan RSA-OAEP.
  final oaep = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(parseRsaPublicKey(publicKeyDer)));
  final keymat = oaep.process(Uint8List.fromList([...keyBytes, ...nonce]));

  return '$kPiiMarker${base64.encode(keymat)}.${base64.encode(payload)}';
}

/// Parse kunci publik RSA dari DER SPKI:
/// SEQUENCE { AlgorithmIdentifier, BIT STRING { SEQUENCE { n, e } } }
RSAPublicKey parseRsaPublicKey(Uint8List der) {
  final outer = ASN1Parser(der).nextObject() as ASN1Sequence;
  final bitString = outer.elements![1] as ASN1BitString;

  // stringValues = isi BIT STRING tanpa byte unused-bits.
  final inner =
      ASN1Parser(Uint8List.fromList(bitString.stringValues!)).nextObject()
          as ASN1Sequence;
  final modulus = (inner.elements![0] as ASN1Integer).integer!;
  final exponent = (inner.elements![1] as ASN1Integer).integer!;

  return RSAPublicKey(modulus, exponent);
}

/// Buka segel memakai kunci privat RSA — dipakai pengujian Dart
/// untuk memastikan putaran kembali lengkap (produksi men-dekripsi
/// di backend memakai kunci privat di .env).
String openPii(String sealed, RSAPrivateKey privateKey) {
  final parts = sealed.substring(kPiiMarker.length).split('.');
  final keymat = _rsaUnwrap(base64Decode(parts[0]), privateKey);
  final payload = base64Decode(parts[1]);

  final keyBytes = keymat.sublist(0, 32);
  final nonce = keymat.sublist(32, 44);

  final gcm = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(keyBytes), 128, nonce, Uint8List(0)));

  final out = Uint8List(payload.length);
  final processed = gcm.processBytes(payload, 0, payload.length, out, 0);
  // doFinal menulis blok terakhir DAN memverifikasi tag GCM (16
  // byte terakhir payload) — melempar bila tidak cocok.
  final flushed = gcm.doFinal(out, processed);

  return utf8.decode(out.sublist(0, processed + flushed));
}

Uint8List _rsaUnwrap(Uint8List envelope, RSAPrivateKey privateKey) {
  final oaep = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

  return oaep.process(envelope);
}

Uint8List _randomBytes(int length, math.Random random) =>
    Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));

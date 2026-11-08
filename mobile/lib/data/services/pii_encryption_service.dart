import 'dart:convert';
import 'dart:typed_data';

import '../api_client.dart';
import '../pii_crypto.dart';

/// Enkripsi data pribadi (PII) sisi aplikasi mobile — SATU-SATUNYA
/// pihak yang mengenkripsi. Kripto murninya ada di pii_crypto.dart.
///
/// Kunci publik RSA diambil dari GET /api/v1/auth/public-key
/// (sekali per sesi, di-cache). Hanya backend — pemegang kunci
/// PRIVAT di .env — yang bisa membuka: dipakai saat validasi &
/// menampilkan data ke pengguna.
///
/// Jika kunci publik belum bisa diambil (server belum menjalankan
/// `php artisan encryption:generate`, offline, dsb.) nilai dikirim
/// apa adanya — seluruh fitur tetap berjalan (fallback, sama
/// seperti data lama yang plaintext).
class PiiEncryptionService {
  PiiEncryptionService(this._client);

  final ApiClient _client;

  /// Cache kunci publik (SPKI DER) selama sesi aplikasi.
  static Uint8List? _cachedPublicKeyDer;

  /// Ambil kunci publik server (dengan cache sesi).
  Future<Uint8List?> _publicKey() async {
    if (_cachedPublicKeyDer != null) {
      return _cachedPublicKeyDer;
    }

    try {
      final json =
          await _client.get('/api/v1/auth/public-key') as Map<String, dynamic>;
      final der = base64Decode(json['data']['public_key'] as String);

      // Validasi bentuk kunci sebelum dicache.
      parseRsaPublicKey(der);
      _cachedPublicKeyDer = der;

      return _cachedPublicKeyDer;
    } catch (_) {
      return null;
    }
  }

  /// Enkripsi field PII yang diberikan. Nilai kosong/null dilewatkan.
  /// Gagal total -> mengembalikan map asli (fallback plaintext).
  Future<Map<String, String>> encryptFields(Map<String, String?> fields) async {
    final publicKey = await _publicKey();

    if (publicKey == null) {
      return fields.map((key, value) => MapEntry(key, value ?? ''));
    }

    return {
      for (final entry in fields.entries)
        entry.key: (entry.value == null || entry.value!.isEmpty)
            ? (entry.value ?? '')
            : sealPii(entry.value!, publicKey),
    };
  }
}

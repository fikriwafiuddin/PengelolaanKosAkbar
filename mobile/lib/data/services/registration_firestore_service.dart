import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Salinan (mirror) data registrasi ke Firestore — dikirim mobile
/// secara PARALEL dengan API Laravel. MySQL tetap sumber kebenaran:
/// kegagalan mirror hanya dicatat log, tidak pernah menggagalkan
/// registrasi (pola sama dengan FcmService::writeChatMessage di
/// backend).
///
/// Field data pribadi (NIK, no. HP, alamat, penanggung jawab) hanya
/// disimpan dalam bentuk ciphertext `PII1:...` — sama persis dengan
/// yang dikirim ke API. Password TIDAK PERNAH disalin.
class RegistrationFirestoreService {
  /// ID dokumen = email (trim + lowercase) — deterministik sehingga
  /// write mirror tidak perlu menunggu respons API dan keduanya bisa
  /// berjalan paralel.
  @visibleForTesting
  static String docIdFor(String email) => email.trim().toLowerCase();

  /// Tulis salinan registrasi ke collection `registrations`.
  ///
  /// Tidak pernah melempar exception; no-op bila Firebase belum
  /// diinisialisasi (lihat main.dart — init-nya kondisional).
  Future<void> mirrorRegistration({
    required String email,
    required String fullName,
    required String birthDate,
    String? occupation,
    required Map<String, String> pii,
  }) async {
    if (Firebase.apps.isEmpty) {
      debugPrint('RegistrationFirestoreService: Firebase belum '
          'diinisialisasi, mirror registrasi dilewati');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('registrations')
          .doc(docIdFor(email))
          .set({
        'email': email,
        'full_name': fullName,
        'birth_date': birthDate,
        if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
        'status': 'menunggu_validasi',
        // PII hanya berupa ciphertext PII1:... (map yang sama dengan
        // body yang dikirim ke API — dua sisi tidak akan berselisih).
        'identity_number': pii['identity_number'],
        'phone': pii['phone'],
        if ((pii['address'] ?? '').isNotEmpty) 'address': pii['address'],
        if ((pii['guardian_name'] ?? '').isNotEmpty)
          'guardian_name': pii['guardian_name'],
        'guardian_phone': pii['guardian_phone'],
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Fail-safe: mirror gagal (aturan keamanan, offline, dsb.)
      // tidak boleh menggagalkan registrasi.
      debugPrint('RegistrationFirestoreService: gagal mirror registrasi: $e');
    }
  }

  /// Hapus salinan mirror (best-effort) saat API menolak registrasi
  /// — mis. email duplikat 422 — agar Firestore tidak menyimpan data
  /// hantu. Tidak pernah melempar exception.
  Future<void> deleteMirror(String email) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('registrations')
          .doc(docIdFor(email))
          .delete();
    } catch (e) {
      debugPrint('RegistrationFirestoreService: gagal menghapus mirror: $e');
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/models/user.dart';
import '../data/services/auth_service.dart';
import '../data/services/push_service.dart';

/// Status sesi pengguna aplikasi mobile.
enum AuthStatus { loading, loggedOut, loggedIn }

/// Menyimpan state autentikasi: token, user aktif, dan profil.
///
/// Token disimpan di device (shared_preferences) sehingga sesi
/// bertahan setelah aplikasi ditutup.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._client) : _auth = AuthService(_client);

  final ApiClient _client;
  final AuthService _auth;

  AuthStatus _status = AuthStatus.loading;
  User? _user;

  AuthStatus get status => _status;
  User? get user => _user;

  /// Cek token tersimpan lalu muat profil; dipanggil saat aplikasi start.
  Future<void> bootstrap() async {
    await _client.loadToken();

    if (_client.token == null) {
      _status = AuthStatus.loggedOut;
      notifyListeners();

      return;
    }

    try {
      _user = await _auth.me();
      _status = AuthStatus.loggedIn;
      unawaited(PushService.activate(_client));
    } on ApiException {
      // Token kedaluwarsa / tidak valid — anggap logout.
      await _client.clearToken();
      _status = AuthStatus.loggedOut;
    } finally {
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.login(email: email, password: password);

    await _client.saveToken(result.token);
    _user = result.user;
    _status = AuthStatus.loggedIn;

    // Daftarkan token FCM device ke server (no-op tanpa Firebase).
    unawaited(PushService.activate(_client));

    notifyListeners();
  }

  /// Registrasi calon penghuni. Berhasil = akun dibuat dengan status
  /// menunggu_validasi — tidak ada sesi login; pemanggil mengarahkan
  /// pengguna ke halaman menunggu validasi.
  Future<void> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String fullName,
    required String identityNumber,
    required String phone,
    required String birthDate,
    required String guardianPhone,
    String? address,
    String? occupation,
    String? guardianName,
  }) async {
    await _auth.register(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      fullName: fullName,
      identityNumber: identityNumber,
      phone: phone,
      birthDate: birthDate,
      guardianPhone: guardianPhone,
      address: address,
      occupation: occupation,
      guardianName: guardianName,
    );
  }

  /// Perbarui profil (dari halaman Ubah Profil) lalu segarkan user aktif.
  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String birthDate,
    required String guardianPhone,
    String? address,
    String? occupation,
    String? guardianName,
  }) async {
    _user = await _auth.updateProfile(
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
      guardianPhone: guardianPhone,
      address: address,
      occupation: occupation,
      guardianName: guardianName,
    );
    notifyListeners();
  }

  /// Segarkan profil dari server (mis. setelah membuka ulang aplikasi).
  Future<void> refreshProfile() async {
    if (_status != AuthStatus.loggedIn) {
      return;
    }

    try {
      _user = await _auth.me();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await forceLogout();
      }
    }
  }

  Future<void> logout() async {
    // Lepas token FCM device dari server sebelum sesi berakhir
    // (no-op tanpa Firebase).
    await PushService.deactivate(_client);

    try {
      await _auth.logout();
    } on ApiException {
      // Abaikan kegagalan jaringan saat logout — token lokal tetap dihapus.
    }

    await forceLogout();
  }

  /// Hapus sesi lokal tanpa memanggil server (saat 401 / token rusak).
  Future<void> forceLogout() async {
    await _client.clearToken();
    _user = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}

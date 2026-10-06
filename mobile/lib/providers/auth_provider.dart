import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/models/user.dart';
import '../data/services/auth_service.dart';

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
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String fullName,
    required String identityNumber,
    String? phone,
    String? birthDate,
    String? address,
    String? occupation,
  }) async {
    final result = await _auth.register(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      fullName: fullName,
      identityNumber: identityNumber,
      phone: phone,
      birthDate: birthDate,
      address: address,
      occupation: occupation,
    );

    await _client.saveToken(result.token);
    _user = result.user;
    _status = AuthStatus.loggedIn;
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

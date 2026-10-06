import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Exception standar untuk semua kesalahan pemanggilan API.
class ApiException implements Exception {
  const ApiException(this.message, {this.errors = const {}, this.statusCode});

  /// Pesan utama yang aman ditampilkan ke pengguna.
  final String message;

  /// Error validasi per-field: {'email': ['Email sudah terdaftar.']}.
  final Map<String, List<String>> errors;

  final int? statusCode;

  @override
  String toString() => message;
}

/// Pembungkus `http` untuk REST API Kost Akbar:
/// menyisipkan token Bearer, timeout, dan menerjemahkan
/// bentuk error Laravel (validasi / 401 / server) ke ApiException.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _tokenKey = 'api_token';

  String? _token;

  /// Token yang sedang aktif (null = belum login).
  String? get token => _token;

  /// Muat token tersimpan dari device (dipanggil saat aplikasi start).
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  /// Simpan token login baru.
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Hapus token (logout).
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: {
        ...?query,
      },
    );

    return _send(() => _client.get(uri, headers: _headers));
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    return _send(
      () => _client.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    late http.Response response;

    try {
      response = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Periksa koneksi Anda lalu coba lagi.');
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Pastikan API berjalan dan alamatnya benar.',
      );
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic json;

    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        json = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    // Bentuk error validasi Laravel: {message, errors: {field: [pesan]}}
    if (json is Map<String, dynamic> && json['errors'] is Map) {
      final errors = (json['errors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e.toString()).toList(),
        ),
      );

      throw ApiException(
        (json['message'] as String?) ?? 'Data yang dikirim tidak valid.',
        errors: errors,
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      switch (response.statusCode) {
        401 => 'Sesi Anda berakhir. Silakan masuk kembali.',
        403 => 'Anda tidak memiliki akses untuk aksi ini.',
        404 => 'Data tidak ditemukan.',
        _ => (json is Map && json['message'] is String)
            ? json['message'] as String
            : 'Terjadi kesalahan pada server (${response.statusCode}).',
      },
      statusCode: response.statusCode,
    );
  }
}

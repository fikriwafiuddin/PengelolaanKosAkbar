import '../api_client.dart';
import '../models/user.dart';

/// Autentikasi: registrasi, login, logout, dan profil.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  /// Login dengan email + password, mengembalikan user + token.
  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/api/v1/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;

    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  /// Registrasi calon penghuni: akun + profil identitas sekaligus.
  Future<({User user, String token})> register({
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
    final json = await _client.post('/api/v1/auth/register', body: {
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'full_name': fullName,
      'identity_number': identityNumber,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (birthDate != null && birthDate.isNotEmpty) 'birth_date': birthDate,
      if (address != null && address.isNotEmpty) 'address': address,
      if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
    }) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;

    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  /// Profil user yang sedang login (akun + identitas + kamar disewa).
  Future<User> me() async {
    final json = await _client.get('/api/v1/auth/me') as Map<String, dynamic>;

    return User.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Logout: mencabut token device ini.
  Future<void> logout() async {
    await _client.post('/api/v1/auth/logout');
  }
}

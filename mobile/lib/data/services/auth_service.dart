import '../api_client.dart';
import '../models/user.dart';
import 'pii_encryption_service.dart';

/// Autentikasi: registrasi, login, logout, dan profil.
///
/// Data pribadi (NIK, no. HP, alamat, penanggung jawab) dienkripsi
/// di sisi mobile dengan kunci publik server sebelum dikirim —
/// lihat [PiiEncryptionService]. Server yang menyimpan & membuka
/// bentuk terenkripsinya memakai kunci privat di .env-nya.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;
  late final PiiEncryptionService _pii = PiiEncryptionService(_client);

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
  ///
  /// Akun baru berstatus menunggu_validasi — TIDAK menerima token;
  /// pengguna hanya bisa login setelah admin menyetujui akunnya.
  Future<User> register({
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
    // Enkripsi data pribadi dengan kunci publik server (fallback
    // plaintext bila server belum mengaktifkan enkripsi).
    final pii = await _pii.encryptFields({
      'identity_number': identityNumber,
      'phone': phone,
      'address': address,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
    });

    final json = await _client.post('/api/v1/auth/register', body: {
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'full_name': fullName,
      'identity_number': pii['identity_number'],
      'phone': pii['phone'],
      'birth_date': birthDate,
      if (address != null && address.isNotEmpty) 'address': pii['address'],
      if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
      if (guardianName != null && guardianName.isNotEmpty)
        'guardian_name': pii['guardian_name'],
      'guardian_phone': pii['guardian_phone'],
    }) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Profil user yang sedang login (akun + identitas + kamar disewa).
  Future<User> me() async {
    final json = await _client.get('/api/v1/auth/me') as Map<String, dynamic>;

    return User.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Perbarui profil penghuni (nama, kontak, identitas yang boleh diubah).
  Future<User> updateProfile({
    required String fullName,
    required String phone,
    required String birthDate,
    required String guardianPhone,
    String? address,
    String? occupation,
    String? guardianName,
  }) async {
    // Sama seperti register: data pribadi dikirim terenkripsi.
    final pii = await _pii.encryptFields({
      'phone': phone,
      'address': address,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
    });

    final json = await _client.put('/api/v1/auth/profile', body: {
      'full_name': fullName,
      'phone': pii['phone'],
      'birth_date': birthDate,
      if (address != null && address.isNotEmpty) 'address': pii['address'],
      if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
      if (guardianName != null && guardianName.isNotEmpty)
        'guardian_name': pii['guardian_name'],
      'guardian_phone': pii['guardian_phone'],
    }) as Map<String, dynamic>;

    return User.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Logout: mencabut token device ini.
  Future<void> logout() async {
    await _client.post('/api/v1/auth/logout');
  }
}

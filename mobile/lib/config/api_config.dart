/// Konfigurasi koneksi ke REST API Laravel.
///
/// - Emulator Android: `http://10.0.2.2:8000` (alias host dari dalam emulator)
/// - Device fisik (WiFi yang sama): ganti dengan IP komputer, mis.
///   `http://192.168.1.10:8000`
///
/// Bisa juga dioverride saat build/run:
/// `flutter run --dart-define=API_URL=http://192.168.1.10:8000`
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration timeout = Duration(seconds: 15);

  /// Gabungkan URL gambar relatif dari API (mis. /storage/rooms/1.png)
  /// dengan base URL aktif — menghasilkan URL absolut yang dapat
  /// diakses dari device/emulator mana pun.
  static String? resolveImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return null;
    }

    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    return '$baseUrl${relativeUrl.startsWith('/') ? '' : '/'}$relativeUrl';
  }
}

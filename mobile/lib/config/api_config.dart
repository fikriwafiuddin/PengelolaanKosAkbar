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
}

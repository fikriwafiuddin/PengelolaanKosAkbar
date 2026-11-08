import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // Gunakan secret key 16 karakter
  static const String _secretKey = 'Qwertyui87651234'; 
  
  // Buat IV statis 16 byte yang konsisten (misalnya menggunakan 16 karakter string atau zero bytes)
  static final _iv = encrypt.IV.fromUtf8('1234567890123456'); // Pastikan tepat 16 karakter!

  static String encryptText(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    final key = encrypt.Key.fromUtf8(_secretKey);
    final cipher = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    
    // Gunakan _iv yang sama dan konsisten
    final encrypted = cipher.encrypt(plainText, iv: _iv);
    
    return encrypted.base64;
  }

  static String decryptText(String cipherText) {
    try {
      if (cipherText.isEmpty) return cipherText;
      
      final key = encrypt.Key.fromUtf8(_secretKey);
      final cipher = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      // Gunakan _iv yang sama persis dengan saat enkripsi
      return cipher.decrypt64(cipherText, iv: _iv);
    } catch (e) {
      return cipherText; // Kembalikan teks asli jika gagal dekripsi
    }
  }
}
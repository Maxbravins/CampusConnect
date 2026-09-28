import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = "auth_token";
  static const _themeKey = "theme_mode"; // "light" or "dark"

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _themeKey, value: mode);
  }

  static Future<String?> getThemeMode() async {
    return _storage.read(key: _themeKey);
  }
}
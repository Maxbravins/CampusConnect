#!/usr/bin/env bash
# Run this from inside your frontend/mobile folder:
#   bash setup_mobile_foundation.sh
set -e

mkdir -p lib/config lib/services lib/models

# ---------- lib/config/api_config.dart ----------
cat > lib/config/api_config.dart << 'EOF'
class ApiConfig {
  // Android emulator -> host machine's localhost is 10.0.2.2, NOT 127.0.0.1/localhost.
  // If you're running on Chrome/web or Windows desktop, "localhost" works fine.
  // If you're on a real Android phone on the same Wi-Fi as your PC, use your PC's LAN IP instead.
  static const String baseUrl = "http://10.0.2.2:5000/api";

  // Uncomment this line instead if you're testing on Chrome or Windows desktop:
  // static const String baseUrl = "http://localhost:5000/api";
}
EOF

# ---------- lib/services/storage_service.dart ----------
cat > lib/services/storage_service.dart << 'EOF'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = "auth_token";

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
EOF

# ---------- lib/models/user.dart ----------
cat > lib/models/user.dart << 'EOF'
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json["id"] ?? json["_id"] ?? "",
      fullName: json["fullName"] ?? "",
      email: json["email"] ?? "",
      role: json["role"] ?? "student",
    );
  }
}
EOF

# ---------- lib/services/api_service.dart ----------
cat > lib/services/api_service.dart << 'EOF'
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Thrown when the backend returns a non-2xx response.
/// Carries the status code and the backend's error message so callers
/// (screens) can show something meaningful to the user.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {"Content-Type": "application/json"};
    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body["message"] != null)
        ? body["message"].toString()
        : "Something went wrong (${response.statusCode})";
    throw ApiException(response.statusCode, message);
  }

  static Future<dynamic> get(String path, {bool withAuth = true}) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
    );
    return _decode(response);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> delete(String path, {bool withAuth = true}) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
    );
    return _decode(response);
  }
}
EOF

# ---------- lib/services/auth_service.dart ----------
cat > lib/services/auth_service.dart << 'EOF'
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  /// Registers a new student. Throws [ApiException] on failure
  /// (e.g. duplicate email, missing fields).
  static Future<AppUser> register({
    required String fullName,
    String? studentId,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await ApiService.post(
      "/auth/register",
      {
        "fullName": fullName,
        "studentId": studentId,
        "email": email,
        "phone": phone,
        "password": password,
      },
      withAuth: false,
    );

    await StorageService.saveToken(data["token"]);
    return AppUser.fromJson(data["user"]);
  }

  /// Logs in an existing user. Throws [ApiException] on failure
  /// (wrong credentials, inactive account).
  static Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.post(
      "/auth/login",
      {"email": email, "password": password},
      withAuth: false,
    );

    await StorageService.saveToken(data["token"]);
    return AppUser.fromJson(data["user"]);
  }

  static Future<void> logout() async {
    await StorageService.clearToken();
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
EOF

echo ""
echo "Shared foundation created in lib/config, lib/services, lib/models."
echo ""
echo "Next: add these two packages to pubspec.yaml under 'dependencies:', then run 'flutter pub get':"
echo "  http: ^1.2.0"
echo "  flutter_secure_storage: ^9.0.0"

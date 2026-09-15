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

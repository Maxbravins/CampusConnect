import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
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

  /// Fetches the current user's profile using the stored token.
  /// Used on app startup to restore an admin session without
  /// asking for another login.
  static Future<AppUser> getCurrentUser() async {
    final data = await ApiService.get("/users/me");
    return AppUser.fromJson(data);
  }
}

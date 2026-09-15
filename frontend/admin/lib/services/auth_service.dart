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
}

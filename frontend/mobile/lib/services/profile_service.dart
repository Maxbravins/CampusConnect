import '../models/user_profile.dart';
import 'api_service.dart';

class ProfileService {
  static Future<UserProfile> getMyProfile() async {
    final data = await ApiService.get("/users/me");
    return UserProfile.fromJson(data);
  }

  static Future<UserProfile> updateMyProfile({
    required String fullName,
    required String phone,
  }) async {
    final data = await ApiService.put("/users/me", {
      "fullName": fullName,
      "phone": phone,
    });
    return UserProfile.fromJson(data);
  }
}

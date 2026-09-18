import '../models/admin_user.dart';
import 'api_service.dart';

class UserManagementService {
  static Future<List<AdminUser>> listUsers({String? search}) async {
    final query = (search != null && search.trim().isNotEmpty)
        ? "?search=${Uri.encodeQueryComponent(search.trim())}"
        : "";
    final data = await ApiService.get("/users$query");
    return (data as List).map((json) => AdminUser.fromJson(json)).toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    await ApiService.put("/users/$id/status", {"status": status});
  }
}

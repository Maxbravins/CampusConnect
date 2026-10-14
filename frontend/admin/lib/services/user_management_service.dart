import '../models/admin_user.dart';
import '../models/page_result.dart';
import 'api_service.dart';

class UserManagementService {
  static Future<PageResult<AdminUser>> listUsers({
    String? search,
    int page = 1,
    int limit = 25,
  }) async {
    final parameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }
    final data = await ApiService.get(
      '/users?${Uri(queryParameters: parameters).query}',
    );
    return PageResult.fromJson(data, AdminUser.fromJson);
  }

  static Future<void> updateStatus(String id, String status) async {
    await ApiService.put("/users/$id/status", {"status": status});
  }
}

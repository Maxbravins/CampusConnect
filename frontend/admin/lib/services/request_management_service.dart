import '../models/admin_request.dart';
import '../models/page_result.dart';
import 'api_service.dart';

class RequestManagementService {
  static Future<PageResult<AdminRequest>> listRequests({
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    final parameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (status != null && status != 'All') {
      parameters['status'] = status;
    }
    final data = await ApiService.get(
      '/requests?${Uri(queryParameters: parameters).query}',
    );
    return PageResult.fromJson(data, AdminRequest.fromJson);
  }

  static Future<void> updateStatus(String id, String status) async {
    await ApiService.put("/requests/$id/status", {"status": status});
  }
}

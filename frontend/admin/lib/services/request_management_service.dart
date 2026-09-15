import '../models/admin_request.dart';
import 'api_service.dart';

class RequestManagementService {
  static Future<List<AdminRequest>> listRequests({String? status}) async {
    final query = (status != null && status != "All") ? "?status=$status" : "";
    final data = await ApiService.get("/requests$query");
    return (data as List).map((json) => AdminRequest.fromJson(json)).toList();
  }

  static Future<void> updateStatus(String id, String status) async {
    await ApiService.put("/requests/$id/status", {"status": status});
  }
}

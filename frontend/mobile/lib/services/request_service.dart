import '../models/service_request.dart';
import 'api_service.dart';

class RequestService {
  static const int pageSize = 25;

  static Future<Map<String, dynamic>> createRequest(String serviceId) async {
    final data = await ApiService.post("/requests", {"serviceId": serviceId});
    return data as Map<String, dynamic>;
  }

  static Future<List<ServiceRequest>> listMyRequests({int page = 1}) async {
    final data = await ApiService.get(
      "/requests/mine?page=$page&limit=$pageSize",
    );
    return (data as List).map((json) => ServiceRequest.fromJson(json)).toList();
  }

  /// Cancels an unpaid request. Throws [ApiException] if it's already
  /// been paid/processed, or doesn't belong to the current user.
  static Future<void> cancelRequest(String requestId) async {
    await ApiService.patch("/requests/$requestId/cancel", {});
  }
}

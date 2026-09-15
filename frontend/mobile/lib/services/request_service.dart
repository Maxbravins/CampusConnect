import '../models/service_request.dart';
import 'api_service.dart';

class RequestService {
  static Future<Map<String, dynamic>> createRequest(String serviceId) async {
    final data = await ApiService.post("/requests", {"serviceId": serviceId});
    return data as Map<String, dynamic>;
  }

  static Future<List<ServiceRequest>> listMyRequests() async {
    final data = await ApiService.get("/requests/mine");
    return (data as List).map((json) => ServiceRequest.fromJson(json)).toList();
  }
}

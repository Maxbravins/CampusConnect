import '../models/service.dart';
import 'api_service.dart';

/// Wraps the admin-only /api/services endpoints.
class ServiceManagementService {
  static Future<List<CampusService>> listServices({String? category}) async {
    final query = (category != null && category != "All")
        ? "?category=${Uri.encodeQueryComponent(category)}"
        : "";
    final data = await ApiService.get("/services$query");
    return (data as List).map((json) => CampusService.fromJson(json)).toList();
  }

  static Future<CampusService> createService({
    required String name,
    required String description,
    required num fee,
    required int processingDays,
    required String category,
  }) async {
    final data = await ApiService.post("/services", {
      "name": name,
      "description": description,
      "fee": fee,
      "processingDays": processingDays,
      "category": category,
    });
    return CampusService.fromJson(data);
  }

  static Future<void> deactivateService(String id) async {
    await ApiService.delete("/services/$id");
  }

  static Future<void> reactivateService(String id) async {
    await ApiService.put("/services/$id", {"status": "active"});
  }
}

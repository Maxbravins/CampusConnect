import '../models/service.dart';
import 'api_service.dart';

class ServiceManagementService {
  static Future<List<CampusService>> listServices() async {
    final data = await ApiService.get("/services");
    return (data as List).map((json) => CampusService.fromJson(json)).toList();
  }

  static Future<CampusService> createService({
    required String name,
    required String description,
    required num fee,
    required int processingDays,
  }) async {
    final data = await ApiService.post("/services", {
      "name": name,
      "description": description,
      "fee": fee,
      "processingDays": processingDays,
    });
    return CampusService.fromJson(data);
  }

  static Future<void> deactivateService(String id) async {
    await ApiService.delete("/services/$id");
  }
}

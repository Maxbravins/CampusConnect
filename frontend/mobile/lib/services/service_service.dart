import '../models/service.dart';
import 'api_service.dart';

class ServiceService {
  static Future<List<CampusService>> listServices({String? category}) async {
    final query = (category != null && category != "All")
        ? "?category=${Uri.encodeQueryComponent(category)}"
        : "";
    final data = await ApiService.get("/services$query");
    return (data as List).map((json) => CampusService.fromJson(json)).toList();
  }
}

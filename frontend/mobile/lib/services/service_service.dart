import '../models/service.dart';
import 'api_service.dart';

class ServiceService {
  static Future<List<CampusService>> listServices() async {
    final data = await ApiService.get("/services");
    return (data as List).map((json) => CampusService.fromJson(json)).toList();
  }
}

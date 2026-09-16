import '../models/dashboard_stats.dart';
import 'api_service.dart';

class ReportService {
  static Future<DashboardStats> getDashboardStats() async {
    final data = await ApiService.get("/reports/dashboard");
    return DashboardStats.fromJson(data);
  }
}

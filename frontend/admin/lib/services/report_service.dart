import '../models/dashboard_stats.dart';
import 'api_service.dart';

class ReportService {
  static Future<DashboardStats> getDashboardStats() async {
    final data = await ApiService.get("/reports/dashboard");
    return DashboardStats.fromJson(data);
  }

  static Future<String> exportRequestsCsv() async {
    return ApiService.getRaw("/reports/export/requests");
  }

  static Future<String> exportPaymentsCsv() async {
    return ApiService.getRaw("/reports/export/payments");
  }
}

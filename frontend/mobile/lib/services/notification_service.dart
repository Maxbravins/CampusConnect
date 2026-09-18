import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  static Future<List<AppNotification>> listMyNotifications() async {
    final data = await ApiService.get("/notifications/mine");
    return (data as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  static Future<void> markAsRead(String id) async {
    await ApiService.put("/notifications/$id/read", {});
  }
}

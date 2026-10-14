import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  static const int pageSize = 25;

  static Future<List<AppNotification>> listMyNotifications({int page = 1}) async {
    final data = await ApiService.get(
      "/notifications/mine?page=$page&limit=$pageSize",
    );
    return (data as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  static Future<int> unreadCount() async {
    final data = await ApiService.get("/notifications/unread-count");
    return (data as Map<String, dynamic>)["count"] as int;
  }

  static Future<void> markAsRead(String id) async {
    await ApiService.put("/notifications/$id/read", {});
  }
}

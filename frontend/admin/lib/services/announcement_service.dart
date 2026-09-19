import 'api_service.dart';

class AnnouncementService {
  static Future<List<dynamic>> listAnnouncements() async {
    final data = await ApiService.get("/announcements");
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String message,
  }) async {
    final data = await ApiService.post("/announcements", {
      "title": title,
      "message": message,
    });

    return data as Map<String, dynamic>;
  }
}
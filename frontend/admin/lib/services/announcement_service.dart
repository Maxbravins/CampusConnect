import 'api_service.dart';

class AnnouncementService {
  static const int pageSize = 25;

  static Future<List<dynamic>> listAnnouncements({int page = 1}) async {
    final data = await ApiService.get(
      "/announcements?page=$page&limit=$pageSize",
    );
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

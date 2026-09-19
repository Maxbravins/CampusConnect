import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static Future<List<Announcement>> listAnnouncements() async {
    final data = await ApiService.get("/announcements");

    return (data as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }
}
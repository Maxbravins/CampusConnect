import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static const int pageSize = 25;

  static Future<List<Announcement>> listAnnouncements({int page = 1}) async {
    final data = await ApiService.get(
      "/announcements?page=$page&limit=$pageSize",
    );

    return (data as List)
        .map((json) => Announcement.fromJson(json))
        .toList();
  }
}

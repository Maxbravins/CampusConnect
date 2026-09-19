class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json["_id"] ?? "",
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
    );
  }
}
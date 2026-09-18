class AppNotification {
  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json["_id"] ?? "",
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      read: json["read"] ?? false,
      createdAt: json["createdAt"] != null ? DateTime.tryParse(json["createdAt"]) : null,
    );
  }
}

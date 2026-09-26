class CampusService {
  final String id;
  final String name;
  final String description;
  final String category;
  final num fee;
  final int processingDays;
  final String status;

  CampusService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.fee,
    required this.processingDays,
    required this.status,
  });

  factory CampusService.fromJson(Map<String, dynamic> json) {
    return CampusService(
      id: json["_id"] ?? "",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      category: json["category"] ?? "General",
      fee: json["fee"] ?? 0,
      processingDays: json["processingDays"] ?? 1,
      status: json["status"] ?? "active",
    );
  }
}

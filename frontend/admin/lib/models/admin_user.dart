class AdminUser {
  final String id;
  final String fullName;
  final String? studentId;
  final String email;
  final String phone;
  final String role;
  final String status;

  AdminUser({
    required this.id,
    required this.fullName,
    this.studentId,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json["_id"] ?? "",
      fullName: json["fullName"] ?? "",
      studentId: json["studentId"],
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      role: json["role"] ?? "student",
      status: json["status"] ?? "active",
    );
  }
}

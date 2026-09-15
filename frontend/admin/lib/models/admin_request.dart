class AdminRequest {
  final String id;
  final String requestNumber;
  final String studentName;
  final String studentEmail;
  final String serviceName;
  final num serviceFee;
  final String status;
  final DateTime? submittedAt;

  AdminRequest({
    required this.id,
    required this.requestNumber,
    required this.studentName,
    required this.studentEmail,
    required this.serviceName,
    required this.serviceFee,
    required this.status,
    this.submittedAt,
  });

  factory AdminRequest.fromJson(Map<String, dynamic> json) {
    final student = json["student"];
    final service = json["service"];

    return AdminRequest(
      id: json["_id"] ?? "",
      requestNumber: json["requestNumber"] ?? "",
      studentName: (student is Map) ? (student["fullName"] ?? "Unknown") : "Unknown",
      studentEmail: (student is Map) ? (student["email"] ?? "") : "",
      serviceName: (service is Map) ? (service["name"] ?? "Unknown service") : "Unknown service",
      serviceFee: (service is Map) ? (service["fee"] ?? 0) : 0,
      status: json["status"] ?? "Pending",
      submittedAt: json["submittedAt"] != null ? DateTime.tryParse(json["submittedAt"]) : null,
    );
  }
}

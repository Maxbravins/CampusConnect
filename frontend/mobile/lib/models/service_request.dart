class ServiceRequest {
  final String id;
  final String requestNumber;
  final String serviceName;
  final num serviceFee;
  final String status;
  final DateTime? submittedAt;
  final DateTime? completedAt;

  ServiceRequest({
    required this.id,
    required this.requestNumber,
    required this.serviceName,
    required this.serviceFee,
    required this.status,
    this.submittedAt,
    this.completedAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final service = json["service"];
    final serviceName = (service is Map) ? (service["name"] ?? "Unknown service") : "Unknown service";
    final serviceFee = (service is Map) ? (service["fee"] ?? 0) : 0;

    return ServiceRequest(
      id: json["_id"] ?? "",
      requestNumber: json["requestNumber"] ?? "",
      serviceName: serviceName,
      serviceFee: serviceFee,
      status: json["status"] ?? "Pending",
      submittedAt: json["submittedAt"] != null ? DateTime.tryParse(json["submittedAt"]) : null,
      completedAt: json["completedAt"] != null ? DateTime.tryParse(json["completedAt"]) : null,
    );
  }
}

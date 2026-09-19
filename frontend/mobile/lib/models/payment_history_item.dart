class PaymentHistoryItem {
  final String id;
  final String serviceName;
  final String requestNumber;
  final num amount;
  final String phoneNumber;
  final String? transactionReference;
  final String status;
  final DateTime? createdAt;

  PaymentHistoryItem({
    required this.id,
    required this.serviceName,
    required this.requestNumber,
    required this.amount,
    required this.phoneNumber,
    this.transactionReference,
    required this.status,
    this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    final request = json["request"];
    final service = (request is Map) ? request["service"] : null;

    return PaymentHistoryItem(
      id: json["_id"] ?? "",
      serviceName: (service is Map) ? (service["name"] ?? "Unknown service") : "Unknown service",
      requestNumber: (request is Map) ? (request["requestNumber"] ?? "") : "",
      amount: json["amount"] ?? 0,
      phoneNumber: json["phoneNumber"] ?? "",
      transactionReference: json["transactionReference"],
      status: json["status"] ?? "Pending",
      createdAt: json["createdAt"] != null ? DateTime.tryParse(json["createdAt"]) : null,
    );
  }
}

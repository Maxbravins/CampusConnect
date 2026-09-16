class DashboardStats {
  final int totalStudents;
  final int totalRequests;
  final int pendingRequests;
  final int completedRequests;
  final int successfulPaymentsCount;
  final num successfulPaymentsTotal;
  final List<RecentRequest> recentRequests;
  final List<RecentTransaction> recentTransactions;

  DashboardStats({
    required this.totalStudents,
    required this.totalRequests,
    required this.pendingRequests,
    required this.completedRequests,
    required this.successfulPaymentsCount,
    required this.successfulPaymentsTotal,
    required this.recentRequests,
    required this.recentTransactions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json["totalStudents"] ?? 0,
      totalRequests: json["totalRequests"] ?? 0,
      pendingRequests: json["pendingRequests"] ?? 0,
      completedRequests: json["completedRequests"] ?? 0,
      successfulPaymentsCount: json["successfulPaymentsCount"] ?? 0,
      successfulPaymentsTotal: json["successfulPaymentsTotal"] ?? 0,
      recentRequests: (json["recentRequests"] as List? ?? [])
          .map((r) => RecentRequest.fromJson(r))
          .toList(),
      recentTransactions: (json["recentTransactions"] as List? ?? [])
          .map((t) => RecentTransaction.fromJson(t))
          .toList(),
    );
  }
}

class RecentRequest {
  final String requestNumber;
  final String studentName;
  final String serviceName;
  final String status;

  RecentRequest({
    required this.requestNumber,
    required this.studentName,
    required this.serviceName,
    required this.status,
  });

  factory RecentRequest.fromJson(Map<String, dynamic> json) {
    final student = json["student"];
    final service = json["service"];
    return RecentRequest(
      requestNumber: json["requestNumber"] ?? "",
      studentName: (student is Map) ? (student["fullName"] ?? "Unknown") : "Unknown",
      serviceName: (service is Map) ? (service["name"] ?? "Unknown") : "Unknown",
      status: json["status"] ?? "",
    );
  }
}

class RecentTransaction {
  final String studentName;
  final num amount;
  final String? transactionReference;

  RecentTransaction({
    required this.studentName,
    required this.amount,
    this.transactionReference,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> json) {
    final student = json["student"];
    return RecentTransaction(
      studentName: (student is Map) ? (student["fullName"] ?? "Unknown") : "Unknown",
      amount: json["amount"] ?? 0,
      transactionReference: json["transactionReference"],
    );
  }
}

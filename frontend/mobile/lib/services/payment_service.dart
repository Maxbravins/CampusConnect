import '../models/payment_history_item.dart';
import 'api_service.dart';

class PaymentService {
  /// Initiates an M-Pesa STK push for the given request.
  /// Returns the backend's response, which includes the created payment
  /// record and the raw Daraja STK response.
  static Future<Map<String, dynamic>> initiatePayment({
    required String requestId,
    required String phoneNumber,
  }) async {
    final data = await ApiService.post("/payments/initiate", {
      "requestId": requestId,
      "phoneNumber": phoneNumber,
    });
    return data as Map<String, dynamic>;
  }

  /// Fetches the logged-in student's own payment history, newest first.
  static Future<List<PaymentHistoryItem>> listMyPayments() async {
    final data = await ApiService.get("/payments/mine");
    return (data as List).map((json) => PaymentHistoryItem.fromJson(json)).toList();
  }
}

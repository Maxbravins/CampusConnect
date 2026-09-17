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
}

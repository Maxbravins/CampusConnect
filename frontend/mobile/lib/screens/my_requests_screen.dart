import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/request_service.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await RequestService.listMyRequests();
      setState(() => _requests = requests);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmLogout(context);
    if (!confirmed) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _payNow(ServiceRequest request) async {
    final phoneController = TextEditingController(text: "254708374149");
    final formKey = GlobalKey<FormState>();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Pay via M-Pesa", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softLilacContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(request.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("KES ${request.serviceFee}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "M-Pesa Phone Number",
                        prefixIcon: Icon(Icons.phone_android, color: AppTheme.electricIndigo),
                        helperText: "Sandbox test number is pre-filled for testing",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Enter a phone number" : null,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            await PaymentService.initiatePayment(
                              requestId: request.id,
                              phoneNumber: phoneController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Payment STK push sent! Complete prompt on phone, then refresh.",
                                ),
                                duration: Duration(seconds: 5),
                              ),
                            );
                            _loadRequests();
                          } on ApiException catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = e.message;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = "Could not reach the server.";
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Send STK Push"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(
        title: const Text("My Requests"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricIndigo));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadRequests, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text("You haven't submitted any requests yet. Browse Campus Services to get started."),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        final statusColor = AppTheme.getStatusColor(request.status);
        final statusBg = AppTheme.getStatusBgColor(request.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.softLilacContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppTheme.electricIndigo, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.serviceName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                      const SizedBox(height: 4),
                      Text("Ref: ${request.requestNumber}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text("Fee: KES ${request.serviceFee}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo, fontSize: 13)),
                          const SizedBox(width: 12),
                          Text("Submitted: ${_formatDate(request.submittedAt)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                request.status == "Payment Required"
                    ? ElevatedButton.icon(
                        onPressed: () => _payNow(request),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text("Pay Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          request.status,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}


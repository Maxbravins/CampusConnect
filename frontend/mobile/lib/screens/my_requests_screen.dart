import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/request_service.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';

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

  Color _statusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.grey;
      case "Payment Required":
        return Colors.orange;
      case "Paid":
        return Colors.blue;
      case "Processing":
        return Colors.purple;
      case "Completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
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
              title: const Text("Pay with M-Pesa"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${request.serviceName} — KES ${request.serviceFee}"),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "M-Pesa phone number",
                        border: OutlineInputBorder(),
                        helperText: "Sandbox test number is pre-filled — leave as is for testing",
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Enter a phone number" : null,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(dialogError!, style: const TextStyle(color: Colors.red)),
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
                                  "Payment request sent. Check for the M-Pesa prompt, then refresh in a few seconds.",
                                ),
                                duration: Duration(seconds: 5),
                              ),
                            );
                          } on ApiException catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = e.message;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = "Could not reach the server. Check your connection and try again.";
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Send Request"),
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
      appBar: AppBar(
        title: const Text("My Requests"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return ListTile(
          title: Text(request.serviceName),
          subtitle: Text(
            "Ref: ${request.requestNumber}\n"
            "Fee: KES ${request.serviceFee} · Submitted: ${_formatDate(request.submittedAt)}",
          ),
          isThreeLine: true,
          trailing: request.status == "Payment Required"
              ? ElevatedButton(
                  onPressed: () => _payNow(request),
                  child: const Text("Pay Now"),
                )
              : Chip(
                  label: Text(
                    request.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _statusColor(request.status),
                ),
        );
      },
    );
  }
}

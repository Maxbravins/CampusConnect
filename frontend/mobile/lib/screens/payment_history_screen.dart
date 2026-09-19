import 'package:flutter/material.dart';
import '../models/payment_history_item.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentHistoryItem> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payments = await PaymentService.listMyPayments();
      setState(() => _payments = payments);
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
      case "Success":
        return Colors.green;
      case "Failed":
        return Colors.red;
      case "Pending":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPayments),
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
            ElevatedButton(onPressed: _loadPayments, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: Text("No payments yet. Pay for a request to see it here."),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return ListTile(
          title: Text(payment.serviceName),
          subtitle: Text(
            "Ref: ${payment.requestNumber}\n"
            "${payment.phoneNumber} · ${_formatDate(payment.createdAt)}"
            "${payment.transactionReference != null ? '\nTxn: ${payment.transactionReference}' : ''}",
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "KES ${payment.amount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text(
                  payment.status,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: _statusColor(payment.status),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}

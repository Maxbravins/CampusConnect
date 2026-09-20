import 'package:flutter/material.dart';
import '../models/payment_history_item.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

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

  Color _statusColor(String status) {
    switch (status) {
      case "Success":
        return const Color(0xFF10B981);
      case "Failed":
        return Colors.red;
      case "Pending":
        return const Color(0xFFF59E0B);
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
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(
        title: const Text("Payment History"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPayments),
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
            ElevatedButton(onPressed: _loadPayments, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: Text("No payments yet. Pay for a request to see it here.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final statusColor = _statusColor(payment.status);

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
                  child: const Icon(Icons.payments_outlined, color: AppTheme.electricIndigo, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.serviceName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                      const SizedBox(height: 4),
                      Text("Ref: ${payment.requestNumber}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("${payment.phoneNumber} · ${_formatDate(payment.createdAt)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      if (payment.transactionReference != null) ...[
                        const SizedBox(height: 2),
                        Text("Txn: ${payment.transactionReference}", style: const TextStyle(color: AppTheme.electricIndigo, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "KES ${payment.amount}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


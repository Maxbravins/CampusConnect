import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import 'login_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String adminName;

  const ReportsScreen({super.key, required this.adminName});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await ReportService.getDashboardStats();
      setState(() => _stats = stats);
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
            ElevatedButton(onPressed: _loadStats, child: const Text("Retry")),
          ],
        ),
      );
    }

    final stats = _stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard("Total Students", stats.totalStudents.toString(), Icons.people),
              _statCard("Total Requests", stats.totalRequests.toString(), Icons.list_alt),
              _statCard("Pending", stats.pendingRequests.toString(), Icons.pending_actions),
              _statCard("Completed", stats.completedRequests.toString(), Icons.check_circle),
              _statCard(
                "Successful Payments",
                "${stats.successfulPaymentsCount} (KES ${stats.successfulPaymentsTotal})",
                Icons.payments,
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text("Recent Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (stats.recentRequests.isEmpty)
            const Text("No requests yet.")
          else
            Card(
              child: Column(
                children: stats.recentRequests
                    .map(
                      (r) => ListTile(
                        title: Text("${r.serviceName} — ${r.studentName}"),
                        subtitle: Text("Ref: ${r.requestNumber}"),
                        trailing: Chip(
                          label: Text(
                            r.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _statusColor(r.status),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 24),

          const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (stats.recentTransactions.isEmpty)
            const Text("No successful payments yet.")
          else
            Card(
              child: Column(
                children: stats.recentTransactions
                    .map(
                      (t) => ListTile(
                        title: Text(t.studentName),
                        subtitle: Text(t.transactionReference ?? "No reference"),
                        trailing: Text(
                          "KES ${t.amount}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

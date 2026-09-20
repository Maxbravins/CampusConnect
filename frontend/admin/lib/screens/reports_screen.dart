import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ReportsScreen extends StatefulWidget {
  final String adminName;
  final bool embedded;

  const ReportsScreen({
    super.key,
    required this.adminName,
    this.embedded = false,
  });

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

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Reports & Analytics — ${widget.adminName}"),
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.electricIndigo),
      );
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "System Overview",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.electricIndigoDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Real-time analytics and statistics for CampusConnect",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, color: AppTheme.electricIndigo),
                onPressed: _loadStats,
                tooltip: "Refresh Stats",
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.softLilacContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard("Total Students", stats.totalStudents.toString(), Icons.people_alt, const Color(0xFF6366F1)),
              _statCard("Total Requests", stats.totalRequests.toString(), Icons.assignment, const Color(0xFF8B5CF6)),
              _statCard("Pending", stats.pendingRequests.toString(), Icons.pending_actions, const Color(0xFFF59E0B)),
              _statCard("Completed", stats.completedRequests.toString(), Icons.check_circle_outline, const Color(0xFF10B981)),
              _statCard(
                "Successful Payments",
                "${stats.successfulPaymentsCount} (KES ${stats.successfulPaymentsTotal})",
                Icons.account_balance_wallet,
                AppTheme.electricIndigo,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Requests Card Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.softLilacContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: AppTheme.electricIndigo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Recent Requests",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (stats.recentRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("No requests recorded yet.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.recentRequests.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.softLilacBorder),
                      itemBuilder: (context, index) {
                        final r = stats.recentRequests[index];
                        final statusColor = AppTheme.getStatusColor(r.status);
                        final statusBg = AppTheme.getStatusBgColor(r.status);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          title: Text(
                            "${r.serviceName} — ${r.studentName}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text("Ref: ${r.requestNumber}", style: const TextStyle(fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              r.status,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Transactions Card Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.softLilacContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_outlined, color: AppTheme.electricIndigo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Recent Transactions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (stats.recentTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("No successful payments recorded yet.", style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.recentTransactions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.softLilacBorder),
                      itemBuilder: (context, index) {
                        final t = stats.recentTransactions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          title: Text(t.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(t.transactionReference ?? "No reference", style: const TextStyle(fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.softLilacContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "KES ${t.amount}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softLilacBorder),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.electricIndigoDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}


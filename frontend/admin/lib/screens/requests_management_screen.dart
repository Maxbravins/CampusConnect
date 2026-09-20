import 'package:flutter/material.dart';
import '../models/admin_request.dart';
import '../services/request_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RequestsManagementScreen extends StatefulWidget {
  final String adminName;
  final bool embedded;

  const RequestsManagementScreen({
    super.key,
    required this.adminName,
    this.embedded = false,
  });

  @override
  State<RequestsManagementScreen> createState() => _RequestsManagementScreenState();
}

class _RequestsManagementScreenState extends State<RequestsManagementScreen> {
  static const _statusOptions = [
    "All",
    "Pending",
    "Payment Required",
    "Paid",
    "Processing",
    "Completed",
  ];

  List<AdminRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = "All";

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
      final requests = await RequestManagementService.listRequests(status: _filter);
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changeStatus(AdminRequest request, String newStatus) async {
    try {
      await RequestManagementService.updateStatus(request.id, newStatus);
      _loadRequests();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Requests Management — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student Service Requests",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                      SizedBox(height: 4),
                      Text("Filter and update request lifecycle statuses", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh, color: AppTheme.electricIndigo),
                    onPressed: _loadRequests,
                    style: IconButton.styleFrom(backgroundColor: AppTheme.softLilacContainer),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = _statusOptions[index];
                    final selected = option == _filter;
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      selectedColor: AppTheme.electricIndigo,
                      backgroundColor: AppTheme.softLilacBg,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.electricIndigoDark,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected ? AppTheme.electricIndigo : AppTheme.softLilacBorder,
                      ),
                      onSelected: (_) {
                        setState(() => _filter = option);
                        _loadRequests();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.softLilacBorder),
        Expanded(child: _buildBody()),
      ],
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
        child: Text("No requests match this filter.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
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
                      Row(
                        children: [
                          Text(
                            request.serviceName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "— ${request.studentName}",
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ref: ${request.requestNumber} · ${request.studentEmail}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text("Fee: KES ${request.serviceFee}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo)),
                          const SizedBox(width: 16),
                          Text("Submitted: ${_formatDate(request.submittedAt)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: request.status,
                  tooltip: "Change Status",
                  onSelected: (newStatus) => _changeStatus(request, newStatus),
                  itemBuilder: (context) => _statusOptions
                      .where((s) => s != "All")
                      .map((s) => PopupMenuItem(value: s, child: Text(s)))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          request.status,
                          style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: statusColor, size: 18),
                      ],
                    ),
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


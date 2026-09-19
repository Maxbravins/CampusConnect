import 'package:flutter/material.dart';
import '../models/admin_request.dart';
import '../services/request_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import 'login_screen.dart';

class RequestsManagementScreen extends StatefulWidget {
  final String adminName;

  const RequestsManagementScreen({super.key, required this.adminName});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Requests — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRequests),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 40,
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
                    onSelected: (_) {
                      setState(() => _filter = option);
                      _loadRequests();
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
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
      return const Center(child: Text("No requests match this filter."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return ListTile(
          title: Text("${request.serviceName} — ${request.studentName}"),
          subtitle: Text(
            "Ref: ${request.requestNumber} · ${request.studentEmail}\n"
            "Fee: KES ${request.serviceFee} · Submitted: ${_formatDate(request.submittedAt)}",
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            initialValue: request.status,
            onSelected: (newStatus) => _changeStatus(request, newStatus),
            itemBuilder: (context) => _statusOptions
                .where((s) => s != "All")
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
            child: Chip(
              label: Text(
                request.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _statusColor(request.status),
            ),
          ),
        );
      },
    );
  }
}

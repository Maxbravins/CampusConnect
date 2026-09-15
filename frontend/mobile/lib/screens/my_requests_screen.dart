import 'package:flutter/material.dart';
import '../models/service_request.dart';
import '../services/request_service.dart';
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
      setState(() => _errorMessage = "Could not reach the server.");
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
        child: Text("You haven't submitted any requests yet."),
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
          trailing: Chip(
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

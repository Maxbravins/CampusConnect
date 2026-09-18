import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_service.dart';
import '../services/request_service.dart';
import '../services/api_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<CampusService> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final services = await ServiceService.listServices();
      setState(() => _services = services);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndRequest(CampusService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service.name),
        content: Text(
          "${service.description}\n\nFee: KES ${service.fee}\n"
          "Estimated processing: ${service.processingDays} day(s)\n\n"
          "Submit a request for this service?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final request = await RequestService.createRequest(service.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Request Submitted"),
          content: Text(
            "Your reference number is:\n\n${request["requestNumber"]}\n\n"
            "Status: ${request["status"]}\n\n"
            "You can use this reference to track your request.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not reach the server. Check your connection and try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Services"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadServices),
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
            ElevatedButton(onPressed: _loadServices, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(child: Text("No services are available right now."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final service = _services[index];
        return ListTile(
          title: Text(service.name),
          subtitle: Text(
            "${service.description}\nFee: KES ${service.fee} · ${service.processingDays} day(s)",
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _confirmAndRequest(service),
        );
      },
    );
  }
}

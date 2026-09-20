import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_service.dart';
import '../services/request_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

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

  Future<void> _confirmAndRequest(CampusService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softLilacContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Fee: KES ${service.fee}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo)),
                  Text("Time: ${service.processingDays} day(s)", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Would you like to submit a request for this service?", style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Request Submitted 🎉", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Your request has been successfully created!"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.softLilacContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.softLilacBorder),
                ),
                child: Column(
                  children: [
                    const Text("REFERENCE NUMBER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.electricIndigo)),
                    const SizedBox(height: 4),
                    Text(
                      "${request["requestNumber"]}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text("Status: ${request["status"]}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Done"),
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
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(
        title: const Text("Campus Services"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadServices),
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
            ElevatedButton(onPressed: _loadServices, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(child: Text("No services are available right now."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _confirmAndRequest(service),
            borderRadius: BorderRadius.circular(16),
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
                    child: const Icon(Icons.miscellaneous_services, color: AppTheme.electricIndigo, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "KES ${service.fee}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "⏱ ${service.processingDays} day(s)",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.electricIndigo),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


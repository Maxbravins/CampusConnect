import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ServicesManagementScreen extends StatefulWidget {
  final String adminName;

  const ServicesManagementScreen({super.key, required this.adminName});

  @override
  State<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
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
      final services = await ServiceManagementService.listServices();
      setState(() => _services = services);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deactivate(CampusService service) async {
    try {
      await ServiceManagementService.deactivateService(service.id);
      _loadServices();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reactivate(CampusService service) async {
    try {
      await ServiceManagementService.reactivateService(service.id);
      _loadServices();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openAddServiceDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final feeController = TextEditingController();
    final daysController = TextEditingController(text: "1");
    final formKey = GlobalKey<FormState>();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Service"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Service name"),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: "Description"),
                      ),
                      TextFormField(
                        controller: feeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: "Fee (KES)"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          if (num.tryParse(v) == null) return "Enter a valid number";
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Processing days"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          if (int.tryParse(v) == null) return "Enter a whole number";
                          return null;
                        },
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 8),
                        Text(dialogError!, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ServiceManagementService.createService(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        fee: num.parse(feeController.text.trim()),
                        processingDays: int.parse(daysController.text.trim()),
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      _loadServices();
                    } on ApiException catch (e) {
                      setDialogState(() => dialogError = e.message);
                    } catch (e) {
                      setDialogState(() => dialogError = "Could not reach the server.");
                    }
                  },
                  child: const Text("Add"),
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
        title: Text("Services — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadServices),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddServiceDialog,
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
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
      return const Center(child: Text("No services yet. Tap \"Add Service\" to create one."));
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
            "${service.description}\nFee: KES ${service.fee} · ${service.processingDays} day(s) · ${service.status}",
          ),
          isThreeLine: true,
          trailing: service.status == "active"
              ? IconButton(
                  icon: const Icon(Icons.block, color: Colors.red),
                  tooltip: "Deactivate",
                  onPressed: () => _deactivate(service),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: "Reactivate",
                  onPressed: () => _reactivate(service),
                ),
        );
      },
    );
  }
}

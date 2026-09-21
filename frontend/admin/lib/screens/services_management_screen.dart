import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ServicesManagementScreen extends StatefulWidget {
  final String adminName;
  final bool embedded;

  const ServicesManagementScreen({
    super.key,
    required this.adminName,
    this.embedded = false,
  });

  @override
  State<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
  List<CampusService> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadServices();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CampusService> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((service) {
      return service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery);
    }).toList();
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Campus Service", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Service Name"),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: "Description"),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Processing Time (Days)"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          if (int.tryParse(v) == null) return "Enter a whole number";
                          return null;
                        },
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
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
                      setDialogState(() => dialogError = "Could not reach the server. Check your connection and try again.");
                    }
                  },
                  child: const Text("Add Service"),
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
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddServiceDialog,
          backgroundColor: AppTheme.electricIndigo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Add Service"),
        ),
        body: _buildBody(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Services Management — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadServices),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddServiceDialog,
        backgroundColor: AppTheme.electricIndigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
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
      return const Center(
        child: Text("No services created yet. Tap \"Add Service\" to create one."),
      );
    }

    final filtered = _filteredServices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                    "Campus Services",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                  ),
                  SizedBox(height: 4),
                  Text("Manage service offerings, fees, and operational status", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, color: AppTheme.electricIndigo),
                onPressed: _loadServices,
                style: IconButton.styleFrom(backgroundColor: AppTheme.softLilacContainer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search services...",
              prefixIcon: const Icon(Icons.search, color: AppTheme.electricIndigo),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.softLilacBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.softLilacBorder),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text("No services match your search.")),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final service = filtered[index];
                final isActive = service.status == "active";
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
                          child: const Icon(Icons.miscellaneous_services, color: AppTheme.electricIndigo, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFD1FAE5) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(service.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text("Fee: KES ${service.fee}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo)),
                                  const SizedBox(width: 16),
                                  Text("Processing: ${service.processingDays} day(s)", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        isActive
                            ? OutlinedButton.icon(
                                onPressed: () => _deactivate(service),
                                icon: const Icon(Icons.block, size: 16, color: Colors.red),
                                label: const Text("Deactivate", style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _reactivate(service),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text("Reactivate"),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

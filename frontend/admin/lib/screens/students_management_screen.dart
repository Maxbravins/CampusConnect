import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../services/user_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import 'login_screen.dart';

class StudentsManagementScreen extends StatefulWidget {
  final String adminName;

  const StudentsManagementScreen({super.key, required this.adminName});

  @override
  State<StudentsManagementScreen> createState() => _StudentsManagementScreenState();
}

class _StudentsManagementScreenState extends State<StudentsManagementScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await UserManagementService.listUsers(search: _searchController.text);
      setState(() => _users = users);
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

  Future<void> _toggleStatus(AdminUser user) async {
    final newStatus = user.status == "active" ? "inactive" : "active";
    try {
      await UserManagementService.updateStatus(user.id, newStatus);
      _loadUsers();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by name, email, or student ID",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loadUsers,
                ),
              ),
              onSubmitted: (_) => _loadUsers(),
            ),
          ),
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
            ElevatedButton(onPressed: _loadUsers, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text("No students found. Try a different search."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isActive = user.status == "active";
        return ListTile(
          title: Text(user.fullName),
          subtitle: Text(
            "${user.email} · ${user.phone}\n"
            "Student ID: ${user.studentId ?? "Not set"}",
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                label: Text(
                  isActive ? "Active" : "Inactive",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: isActive ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isActive ? Icons.block : Icons.check_circle_outline,
                  color: isActive ? Colors.red : Colors.green,
                ),
                tooltip: isActive ? "Deactivate" : "Activate",
                onPressed: () => _toggleStatus(user),
              ),
            ],
          ),
        );
      },
    );
  }
}

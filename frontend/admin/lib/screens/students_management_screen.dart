import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../services/user_management_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class StudentsManagementScreen extends StatefulWidget {
  final String adminName;
  final bool embedded;

  const StudentsManagementScreen({
    super.key,
    required this.adminName,
    this.embedded = false,
  });

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
    if (widget.embedded) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Students Management — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
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
          padding: const EdgeInsets.all(24),
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
                        "Student Directory",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                      SizedBox(height: 4),
                      Text("Search student accounts and activate or deactivate access", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.refresh, color: AppTheme.electricIndigo),
                    onPressed: _loadUsers,
                    style: IconButton.styleFrom(backgroundColor: AppTheme.softLilacContainer),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by student name, email, or ID...",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.electricIndigo),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _loadUsers,
                  ),
                ),
                onSubmitted: (_) => _loadUsers(),
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
            ElevatedButton(onPressed: _loadUsers, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text("No students found. Try a different search query.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isActive = user.status == "active";
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.softLilacContainer,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "S",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricIndigo),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.fullName,
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
                      Text(
                        "${user.email} · ${user.phone}",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Student ID: ${user.studentId ?? "Not assigned"}",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                isActive
                    ? OutlinedButton.icon(
                        onPressed: () => _toggleStatus(user),
                        icon: const Icon(Icons.block, size: 16, color: Colors.red),
                        label: const Text("Deactivate", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _toggleStatus(user),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text("Activate"),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}


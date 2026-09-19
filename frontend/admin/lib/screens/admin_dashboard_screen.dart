import 'package:flutter/material.dart';
import 'services_management_screen.dart';
import 'requests_management_screen.dart';
import 'reports_screen.dart';
import 'students_management_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String adminName;

  const AdminDashboardScreen({super.key, required this.adminName});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmLogout(context);
    if (!confirmed) return;

    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin — $adminName"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text("Reports & Stats"),
                    subtitle: const Text("Overview of students, requests, and payments"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportsScreen(adminName: adminName),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text("Manage Students"),
                    subtitle: const Text("Search students and activate/deactivate accounts"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentsManagementScreen(adminName: adminName),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text("Manage Services"),
                    subtitle: const Text("Add, view, and deactivate campus services"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServicesManagementScreen(adminName: adminName),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text("Manage Requests"),
                    subtitle: const Text("View student requests and update their status"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestsManagementScreen(adminName: adminName),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'services_management_screen.dart';
import 'requests_management_screen.dart';
import 'reports_screen.dart';
import 'students_management_screen.dart';
import 'announcements_management_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminName;

  const AdminDashboardScreen({super.key, required this.adminName});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Reports & Analytics",
    "Requests Management",
    "Services Management",
    "Students Directory",
    "Announcements",
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final screens = [
      ReportsScreen(adminName: widget.adminName, embedded: true),
      RequestsManagementScreen(adminName: widget.adminName, embedded: true),
      ServicesManagementScreen(adminName: widget.adminName, embedded: true),
      StudentsManagementScreen(adminName: widget.adminName, embedded: true),
      AnnouncementsManagementScreen(adminName: widget.adminName, embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.electricIndigo,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "CampusConnect",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.softLilacContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.electricIndigo),
              ),
            ),
            const SizedBox(width: 16),
            if (isDesktop) ...[
              const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.normal),
              ),
            ],
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  widget.adminName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              extended: MediaQuery.of(context).size.width >= 1024,
              minExtendedWidth: 200,
              labelType: MediaQuery.of(context).size.width >= 1024
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text("Reports & Stats"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text("Requests"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text("Services"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text("Students"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: Text("Announcements"),
                ),
              ],
            ),
          const VerticalDivider(thickness: 1, width: 1, color: AppTheme.softLilacBorder),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: "Reports",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: "Requests",
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: "Services",
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: "Students",
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: "Announce",
                ),
              ],
            ),
    );
  }
}


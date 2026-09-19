import 'package:flutter/material.dart';
import '../models/user.dart';
import 'services_screen.dart';
import 'my_requests_screen.dart';
import 'payment_history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Hosts the 5 main sections behind a persistent bottom navigation bar.
/// Each section keeps its own Scaffold/AppBar (including its own logout
/// button) — only the selected one is visible at a time, so there's no
/// double app bar.
class MainScreen extends StatefulWidget {
  final AppUser user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ServicesScreen(),
      const MyRequestsScreen(),
      const PaymentHistoryScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: "Services"),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: "Requests"),
          NavigationDestination(icon: Icon(Icons.payment), label: "Payments"),
          NavigationDestination(icon: Icon(Icons.notifications), label: "Alerts"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

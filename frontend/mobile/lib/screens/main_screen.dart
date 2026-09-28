import 'package:flutter/material.dart';
import '../models/user.dart';
import 'home_screen.dart';
import 'services_screen.dart';
import 'my_requests_screen.dart';
import 'payment_history_screen.dart';
import 'profile_screen.dart';
import '../services/theme_service.dart';

/// Hosts the 5 main sections behind a persistent bottom navigation bar.
class MainScreen extends StatefulWidget {
  final AppUser user;

  const MainScreen({
    super.key,
    required this.user,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(user: widget.user),
      const ServicesScreen(),
      const MyRequestsScreen(),
      const PaymentHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
     bottomNavigationBar: Row(
  children: [
    Expanded(
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: "Services",
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: "Requests",
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: "Payments",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    ),

    ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          height: 80,
          width: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: IconButton(
            tooltip: isDark ? "Switch to light mode" : "Switch to dark mode",
            onPressed: ThemeService.toggleTheme,
            icon: Icon(
              isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        );
      },
    ),
  ],
)
    );
  }
}
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import 'admin_dashboard_screen.dart';

/// Shown briefly on every app startup (including a browser refresh).
/// Checks whether a valid admin session already exists — if so, skips
/// straight to the dashboard instead of forcing another login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await AuthService.isLoggedIn();

    if (!loggedIn) {
      _goToWelcome();
      return;
    }

    try {
      final user = await AuthService.getCurrentUser();

      if (user.role != "admin") {
        await AuthService.logout();
        _goToWelcome();
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboardScreen(adminName: user.fullName)),
      );
    } catch (_) {
      await AuthService.logout();
      _goToWelcome();
    }
  }

  void _goToWelcome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

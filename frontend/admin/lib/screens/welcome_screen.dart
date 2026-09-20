import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.softLilacBorder, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.softLilacContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.electricIndigo),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "CampusConnect Admin",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.electricIndigoDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Comprehensive portal to manage services, student requests, users, and analytical reports.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text("Log In to Admin Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


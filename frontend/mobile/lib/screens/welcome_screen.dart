import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

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
                          decoration: const BoxDecoration(
                            color: AppTheme.softLilacContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, size: 64, color: AppTheme.electricIndigo),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "CampusConnect",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.electricIndigoDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Campus services, requests, and instant M-Pesa payments — all in one seamless experience.",
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
                          child: const Text("Log In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text("Create an Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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


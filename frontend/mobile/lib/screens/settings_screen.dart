import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/dialogs.dart';
import 'forgot_password_screen.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmLogout(context);
    if (!confirmed) return;

    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel("Appearance"),
          Card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeMode,
              builder: (context, themeMode, _) {
                final isDark = themeMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: AppTheme.electricIndigo,
                  ),
                  title: const Text("Dark Mode"),
                  subtitle: Text(isDark ? "Dark appearance is enabled" : "Use a dark appearance"),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => ThemeService.toggleTheme(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel("Account"),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppTheme.electricIndigo),
                  title: const Text("Change Password"),
                  subtitle: const Text("Reset your password via email OTP"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Log Out", style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel("About"),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppTheme.electricIndigo),
                  title: Text("CampusConnect"),
                  subtitle: Text("Version 1.0.0"),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.support_agent_outlined, color: AppTheme.electricIndigo),
                  title: Text("Need help?"),
                  subtitle: Text("Contact your campus administration office"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
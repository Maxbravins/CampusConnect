import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CampusConnectAdminApp());
}

class CampusConnectAdminApp extends StatelessWidget {
  const CampusConnectAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CampusConnect Admin",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

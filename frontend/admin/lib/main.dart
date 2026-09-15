import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

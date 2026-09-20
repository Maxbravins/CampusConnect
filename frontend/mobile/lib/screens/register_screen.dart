import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.register(
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim().isEmpty
            ? null
            : _studentIdController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(user: user)),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(title: const Text("Create Student Account")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.softLilacBorder, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Join CampusConnect",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.electricIndigoDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Create your account to request services and track payments",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.electricIndigo),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? "Enter your full name" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _studentIdController,
                          decoration: const InputDecoration(
                            labelText: "Student ID (optional)",
                            prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.electricIndigo),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.electricIndigo),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Enter your email";
                            if (!value.contains("@")) return "Enter a valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.electricIndigo),
                            hintText: "e.g. 2547XXXXXXXX",
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? "Enter your phone number" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.electricIndigo),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Enter a password";
                            if (value.length < 6) return "Password must be at least 6 characters";
                            return null;
                          },
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Complete Registration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _saveMessage;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ProfileService.getMyProfile();
      setState(() {
        _profile = profile;
        _fullNameController.text = profile.fullName;
        _phoneController.text = profile.phone;
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmLogout(context);
    if (!confirmed) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveMessage = null;
    });

    try {
      final updated = await ProfileService.updateMyProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      setState(() {
        _profile = updated;
        _saveMessage = "Profile updated successfully!";
      });
    } on ApiException catch (e) {
      setState(() => _saveMessage = e.message);
    } catch (e) {
      setState(() => _saveMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricIndigo));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadProfile, child: const Text("Retry")),
          ],
        ),
      );
    }

    final profile = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.softLilacContainer,
                      child: Text(
                        profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : "S",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.electricIndigo),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                    ),
                    const SizedBox(height: 4),
                    Text(profile.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Details Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: profile.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.electricIndigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: profile.studentId ?? "Not assigned",
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Student ID",
                        prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.electricIndigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.electricIndigo),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.electricIndigo),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),

                    if (_saveMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.softLilacContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _saveMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.electricIndigo, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


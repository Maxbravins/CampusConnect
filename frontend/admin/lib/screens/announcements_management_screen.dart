import 'package:flutter/material.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  final String adminName;
  final bool embedded;

  const AnnouncementsManagementScreen({
    super.key,
    required this.adminName,
    this.embedded = false,
  });

  @override
  State<AnnouncementsManagementScreen> createState() =>
      _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState
    extends State<AnnouncementsManagementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  List<dynamic> _announcements = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await AnnouncementService.listAnnouncements();

      if (!mounted) return;

      setState(() {
        _announcements = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _createAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both a title and message"),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AnnouncementService.createAnnouncement(
        title: title,
        message: message,
      );

      _titleController.clear();
      _messageController.clear();

      await _loadAnnouncements();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Announcement published successfully"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmLogout(context);
    if (!confirmed) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements Management — ${widget.adminName}"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnnouncements),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Campus Announcements",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                  ),
                  SizedBox(height: 4),
                  Text("Create and broadcast announcements to students", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, color: AppTheme.electricIndigo),
                onPressed: _loadAnnouncements,
                style: IconButton.styleFrom(backgroundColor: AppTheme.softLilacContainer),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Announcement Creator Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.softLilacContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign, color: AppTheme.electricIndigo),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "New Announcement",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.electricIndigoDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      hintText: "e.g. End of Semester Exam Schedule",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Message",
                      hintText: "Enter the announcement message for students...",
                    ),
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _createAnnouncement,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _saving ? "Publishing..." : "Publish Announcement",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            "Published Announcements",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.electricIndigoDark,
            ),
          ),

          const SizedBox(height: 12),

          _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppTheme.electricIndigo),
                  ),
                )
              : _announcements.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text("No announcements published yet.", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = _announcements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.softLilacContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.campaign, color: AppTheme.electricIndigo, size: 22),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        announcement["title"] ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.electricIndigoDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        announcement["message"] ?? "",
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
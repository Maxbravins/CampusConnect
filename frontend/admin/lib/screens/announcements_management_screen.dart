import 'package:flutter/material.dart';
import '../services/announcement_service.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  final String adminName;

  const AnnouncementsManagementScreen({
    super.key,
    required this.adminName,
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

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Create Announcement",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: "Message",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _createAnnouncement,
                            icon: const Icon(Icons.send),
                            label: Text(
                              _saving
                                  ? "Publishing..."
                                  : "Publish Announcement",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Recent Announcements",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _announcements.isEmpty
                          ? const Center(
                              child: Text("No announcements yet"),
                            )
                          : ListView.builder(
                              itemCount: _announcements.length,
                              itemBuilder: (context, index) {
                                final announcement =
                                    _announcements[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.campaign),
                                    ),
                                    title: Text(
                                      announcement["title"] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 8),
                                      child: Text(
                                        announcement["message"] ?? "",
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
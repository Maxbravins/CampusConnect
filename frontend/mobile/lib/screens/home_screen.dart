import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import 'announcements_screen.dart';
import 'services_screen.dart';
import 'my_requests_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Announcement? _latestAnnouncement;
  bool _isLoadingAnnouncement = true;
  int _unreadNotifications = 0;
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadLatestAnnouncement();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final notifications =
          await NotificationService.listMyNotifications();

      if (!mounted) return;

      setState(() {
        _unreadNotifications =
            notifications.where((notification) => !notification.read).length;
        _isLoadingNotifications = false;
      });
    } on ApiException {
      if (!mounted) return;

      setState(() {
        _isLoadingNotifications = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _loadLatestAnnouncement() async {
    try {
      final announcements =
          await AnnouncementService.listAnnouncements();

      if (!mounted) return;

      setState(() {
        _latestAnnouncement =
            announcements.isNotEmpty ? announcements.first : null;
        _isLoadingAnnouncement = false;
      });
    } on ApiException {
      if (!mounted) return;

      setState(() {
        _isLoadingAnnouncement = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingAnnouncement = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CampusConnect"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatestAnnouncement,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Welcome, ${widget.user.fullName}!",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Access your campus services quickly and easily.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.list_alt,
                      title: "Services",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ServicesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.receipt_long,
                      title: "Requests",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyRequestsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.notifications,
                      title: "Notifications",
                      badgeCount: _isLoadingNotifications
                          ? null
                          : _unreadNotifications,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      context,
                      icon: Icons.campaign,
                      title: "Announcements",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnnouncementsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "Latest Announcement",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (_isLoadingAnnouncement)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_latestAnnouncement == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No announcements yet.",
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.campaign),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _latestAnnouncement!.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _latestAnnouncement!.message,
                          style: const TextStyle(fontSize: 15),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _formatDate(
                            _latestAnnouncement!.createdAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AnnouncementsScreen(),
                              ),
                            );
                          },
                          child: const Text("View all announcements"),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 12,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 32,
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount > 99 ? "99+" : "$badgeCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

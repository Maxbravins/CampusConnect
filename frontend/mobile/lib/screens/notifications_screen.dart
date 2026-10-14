import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import 'welcome_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) return;
    final requestedPage = loadMore ? _page + 1 : 1;
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      final notifications = await NotificationService.listMyNotifications(
        page: requestedPage,
      );
      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _notifications.addAll(notifications);
        } else {
          _notifications = notifications;
        }
        _page = requestedPage;
        _hasMore = notifications.length == NotificationService.pageSize;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (loadMore) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      if (loadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not load more notifications.")),
        );
      } else {
        setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
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
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _handleTap(AppNotification notification) async {
    if (!notification.read) {
      try {
        await NotificationService.markAsRead(notification.id);
        _loadNotifications();
      } on ApiException catch (_) {
        // Non-critical — ignore failures marking as read.
      }
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
        title: const Text("Notifications"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNotifications),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadNotifications, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text("No notifications yet. You'll see updates here when your requests or payments change."));
    }

    return ListView.separated(
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _isLoadingMore ? null : () => _loadNotifications(loadMore: true),
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Load more"),
              ),
            ),
          );
        }

        final notification = _notifications[index];
        return ListTile(
          leading: Icon(
            notification.read ? Icons.mail_outline : Icons.mail,
            color: notification.read ? Colors.grey : Colors.indigo,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "${notification.message}\n${_formatDate(notification.createdAt)}",
          ),
          isThreeLine: true,
          onTap: () => _handleTap(notification),
        );
      },
    );
  }
}

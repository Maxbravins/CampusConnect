import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await NotificationService.listMyNotifications();
      setState(() => _notifications = notifications);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = "Could not reach the server. Check your connection and try again.");
    } finally {
      setState(() => _isLoading = false);
    }
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
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
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

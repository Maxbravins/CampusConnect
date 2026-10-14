import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements({bool loadMore = false}) async {
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
      final announcements = await AnnouncementService.listAnnouncements(
        page: requestedPage,
      );

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          _announcements.addAll(announcements);
        } else {
          _announcements = announcements;
        }
        _page = requestedPage;
        _hasMore = announcements.length == AnnouncementService.pageSize;
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
          const SnackBar(content: Text("Could not load more announcements.")),
        );
      } else {
        setState(() => _errorMessage =
            "Could not reach the server. Check your connection and try again.");
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

  String _formatDate(DateTime? date) {
    if (date == null) return "";

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softLilacBg,
      appBar: AppBar(
        title: const Text("Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.electricIndigo),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAnnouncements,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return const Center(
        child: Text("No announcements published yet.", style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      color: AppTheme.electricIndigo,
      onRefresh: _loadAnnouncements,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _announcements.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _announcements.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _isLoadingMore ? null : () => _loadAnnouncements(loadMore: true),
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

          final announcement = _announcements[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.electricIndigoDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.message,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

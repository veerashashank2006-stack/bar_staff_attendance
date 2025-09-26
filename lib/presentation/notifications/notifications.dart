import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_detail_widget.dart';
import './widgets/notification_empty_state_widget.dart';
import './widgets/notification_filter_widget.dart';
import './widgets/notification_search_bar_widget.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, unread, read
  RealtimeChannel? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _subscribeToRealTimeUpdates();
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadNotifications();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notifications: ${e.toString()}';
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _filteredNotifications = notifications;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      throw e;
    }
  }

  void _subscribeToRealTimeUpdates() {
    _realtimeSubscription = NotificationService.subscribeToNotifications(
      onNotificationReceived: (notification) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, notification);
          });
          _applyFilters();

          // Show snackbar for new notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.title),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: AppTheme.onPrimary,
                onPressed: () => _onNotificationTap(notification),
              ),
            ),
          );
        }
      },
      onNotificationUpdated: (notificationId) {
        // Refresh notifications when one is updated
        _loadNotifications();
      },
    );
  }

  void _applyFilters() {
    List<NotificationModel> filtered = _notifications;

    // Apply filter
    switch (_selectedFilter) {
      case 'unread':
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case 'read':
        filtered = filtered.where((n) => n.isRead).toList();
        break;
      default: // 'all'
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              n.message.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() => _filteredNotifications = filtered);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await _loadNotifications();
      setState(() => _errorMessage = null);
    } catch (e) {
      setState(() => _errorMessage = 'Refresh failed: ${e.toString()}');
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    HapticFeedback.lightImpact();

    try {
      // Mark as read if not already
      if (!notification.isRead) {
        await NotificationService.markAsRead(notification.id);

        // Update local state
        setState(() {
          final index =
              _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
        _applyFilters();
      }

      // Show notification details
      _showNotificationDetails(notification);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Still show details even if mark as read fails
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDetailWidget(
        notification: notification,
        onDelete: () => _deleteNotification(notification.id),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);

      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      _applyFilters();

      if (mounted) {
        Navigator.pop(context); // Close detail sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();

      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllRead() async {
    try {
      await NotificationService.deleteAllRead();

      setState(() {
        _notifications = _notifications.where((n) => !n.isRead).toList();
      });
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Read notifications deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete read notifications: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, unreadCount),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: AppTheme.primary,
        backgroundColor: colorScheme.surface,
        child: _isLoading ? _buildLoadingState() : _buildNotificationsContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int unreadCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 4,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: Icons.arrow_back.codePoint.toString(),
          color: colorScheme.onSurface,
          size: 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (unreadCount > 0)
            Text(
              '$unreadCount unread',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        if (_notifications.isNotEmpty)
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: Icons.more_vert.codePoint.toString(),
              color: colorScheme.onSurface,
              size: 24,
            ),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'delete_read':
                  _deleteAllRead();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (unreadCount > 0)
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text('Mark all as read'),
                ),
              const PopupMenuItem(
                value: 'delete_read',
                child: Text('Delete read notifications'),
              ),
            ],
          ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 80.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: 3.h),
              Text(
                'Loading Notifications...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 2.h),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsContent() {
    return Column(
      children: [
        // Search Bar
        NotificationSearchBarWidget(
          onSearchChanged: _onSearchChanged,
        ),

        // Filter Chips
        NotificationFilterWidget(
          selectedFilter: _selectedFilter,
          onFilterChanged: _onFilterChanged,
        ),

        // Notifications List
        Expanded(
          child: _filteredNotifications.isEmpty
              ? NotificationEmptyStateWidget(
                  filterType: _selectedFilter,
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    return NotificationCardWidget(
                      notification: notification.toJson(),
                      onTap: () => _onNotificationTap(notification),
                      onDelete: () => _deleteNotification(notification.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
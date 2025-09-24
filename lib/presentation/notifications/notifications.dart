import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

class _NotificationsState extends State<Notifications>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isMultiSelectMode = false;
  Set<String> _selectedNotifications = {};
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Mock notifications data
  final List<Map<String, dynamic>> _allNotifications = [
    {
      "id": "1",
      "type": "attendance",
      "title": "Clock-in Reminder",
      "message":
          "Don't forget to clock in for your shift today. Your shift starts at 9:00 AM.",
      "timestamp": "2025-01-23T08:30:00.000Z",
      "isRead": false,
      "sender": "HR System",
      "actions": [
        {"label": "Clock In Now", "icon": "access_time", "route": "/qr-scanner"}
      ]
    },
    {
      "id": "2",
      "type": "leave",
      "title": "Leave Request Approved",
      "message":
          "Your leave request for January 25-26, 2025 has been approved by your manager. Enjoy your time off!",
      "timestamp": "2025-01-22T14:15:00.000Z",
      "isRead": false,
      "sender": "Sarah Johnson - Manager",
      "actions": [
        {
          "label": "View Leave Details",
          "icon": "event_available",
          "route": "/leave-request"
        }
      ]
    },
    {
      "id": "3",
      "type": "schedule",
      "title": "Schedule Update",
      "message":
          "Your shift on January 24th has been moved from 2:00 PM - 10:00 PM to 3:00 PM - 11:00 PM. Please confirm receipt.",
      "timestamp": "2025-01-22T10:45:00.000Z",
      "isRead": true,
      "sender": "Michael Chen - Supervisor"
    },
    {
      "id": "4",
      "type": "system",
      "title": "App Update Available",
      "message":
          "A new version of the Bar Staff Attendance app is available. Update now to get the latest features and improvements.",
      "timestamp": "2025-01-21T16:20:00.000Z",
      "isRead": true,
      "sender": "System Administrator"
    },
    {
      "id": "5",
      "type": "announcement",
      "title": "New Safety Protocols",
      "message":
          "Please review the updated safety protocols effective immediately. All staff must complete the safety training by January 30th.",
      "timestamp": "2025-01-21T09:00:00.000Z",
      "isRead": false,
      "sender": "Operations Team",
      "actions": [
        {"label": "View Protocols", "icon": "security", "route": "/settings"}
      ]
    },
    {
      "id": "6",
      "type": "attendance",
      "title": "Missed Clock-out",
      "message":
          "You forgot to clock out yesterday. Please contact your supervisor to correct your timesheet.",
      "timestamp": "2025-01-20T23:59:00.000Z",
      "isRead": true,
      "sender": "Attendance System"
    },
    {
      "id": "7",
      "type": "leave",
      "title": "Leave Balance Update",
      "message":
          "Your leave balance has been updated. You now have 12 vacation days and 5 sick days remaining for this year.",
      "timestamp": "2025-01-20T12:30:00.000Z",
      "isRead": true,
      "sender": "HR Department"
    },
    {
      "id": "8",
      "type": "schedule",
      "title": "Extra Shift Available",
      "message":
          "An extra shift is available on January 26th from 6:00 PM - 2:00 AM. Contact your manager if interested.",
      "timestamp": "2025-01-19T15:45:00.000Z",
      "isRead": false,
      "sender": "Scheduling Team"
    }
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    List<Map<String, dynamic>> filtered = _allNotifications;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((notification) {
        final title = (notification['title'] as String? ?? '').toLowerCase();
        final message =
            (notification['message'] as String? ?? '').toLowerCase();
        final sender = (notification['sender'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            message.contains(query) ||
            sender.contains(query);
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'unread') {
        filtered = filtered
            .where(
                (notification) => !(notification['isRead'] as bool? ?? false))
            .toList();
      } else {
        filtered = filtered
            .where((notification) => notification['type'] == _selectedFilter)
            .toList();
      }
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now();
      final bTime =
          DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    // Simulate API refresh
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailWidget(
          notification: notification,
          onMarkAsRead: () => _markAsRead(notification['id'] as String),
          onShare: () => _shareNotification(notification),
        ),
      ),
    );

    // Mark as read when opened
    if (!(notification['isRead'] as bool? ?? false)) {
      _markAsRead(notification['id'] as String);
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index =
          _allNotifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _allNotifications[index]['isRead'] = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _allNotifications.removeWhere((n) => n['id'] == notificationId);
      _selectedNotifications.remove(notificationId);
    });
    HapticFeedback.mediumImpact();
  }

  void _shareNotification(Map<String, dynamic> notification) {
    HapticFeedback.lightImpact();
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${notification['title']}'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedNotifications.clear();
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _onSelectionChanged(String notificationId, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selectedNotifications.add(notificationId);
        if (!_isMultiSelectMode) {
          _isMultiSelectMode = true;
        }
      } else {
        _selectedNotifications.remove(notificationId);
        if (_selectedNotifications.isEmpty) {
          _isMultiSelectMode = false;
        }
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _deleteSelected() {
    if (_selectedNotifications.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
            'Are you sure you want to delete ${_selectedNotifications.length} notification(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allNotifications.removeWhere(
                    (n) => _selectedNotifications.contains(n['id']));
                _selectedNotifications.clear();
                _isMultiSelectMode = false;
              });
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteReadNotifications() {
    final readNotifications =
        _allNotifications.where((n) => n['isRead'] as bool? ?? false).toList();

    if (readNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No read notifications to delete'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Read Notifications'),
        content: Text(
            'Are you sure you want to delete ${readNotifications.length} read notification(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allNotifications
                    .removeWhere((n) => n['isRead'] as bool? ?? false);
              });
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: colorScheme.onSurface,
            size: 5.w,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          _isMultiSelectMode
              ? '${_selectedNotifications.length} selected'
              : 'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              onPressed: _deleteSelected,
              icon: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.error,
                size: 5.w,
              ),
              tooltip: 'Delete selected',
            ),
            IconButton(
              onPressed: _toggleMultiSelectMode,
              icon: CustomIconWidget(
                iconName: 'close',
                color: colorScheme.onSurface,
                size: 5.w,
              ),
              tooltip: 'Cancel selection',
            ),
          ] else ...[
            IconButton(
              onPressed: _toggleMultiSelectMode,
              icon: CustomIconWidget(
                iconName: 'checklist',
                color: colorScheme.onSurface,
                size: 5.w,
              ),
              tooltip: 'Select notifications',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'delete_read':
                    _deleteReadNotifications();
                    break;
                  case 'settings':
                    Navigator.pushNamed(context, '/settings');
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read),
                      SizedBox(width: 8),
                      Text('Mark All Read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_read',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep),
                      SizedBox(width: 8),
                      Text('Delete Read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
              ],
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: colorScheme.onSurface,
                size: 5.w,
              ),
            ),
          ],
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          NotificationSearchBarWidget(
            initialQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onClear: () {
              setState(() {
                _searchQuery = '';
              });
            },
          ),

          // Filter chips
          NotificationFilterWidget(
            selectedFilter: _selectedFilter,
            onFilterChanged: _onFilterChanged,
          ),

          // Notifications list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  )
                : filteredNotifications.isEmpty
                    ? NotificationEmptyStateWidget(
                        filterType: _selectedFilter,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshNotifications,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: 2.h),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            final notificationId = notification['id'] as String;

                            return NotificationCardWidget(
                              notification: notification,
                              onTap: () => _onNotificationTap(notification),
                              onMarkAsRead: () => _markAsRead(notificationId),
                              onDelete: () =>
                                  _deleteNotification(notificationId),
                              isSelected: _selectedNotifications
                                  .contains(notificationId),
                              isMultiSelectMode: _isMultiSelectMode,
                              onSelectionChanged: (isSelected) =>
                                  _onSelectionChanged(
                                      notificationId, isSelected),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // Bottom toolbar (multi-select mode)
      bottomNavigationBar: _isMultiSelectMode
          ? Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedNotifications.isEmpty
                            ? null
                            : () {
                                for (final id in _selectedNotifications) {
                                  _markAsRead(id);
                                }
                                setState(() {
                                  _selectedNotifications.clear();
                                  _isMultiSelectMode = false;
                                });
                              },
                        icon: CustomIconWidget(
                          iconName: 'mark_email_read',
                          color: _selectedNotifications.isEmpty
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : AppTheme.primary,
                          size: 4.w,
                        ),
                        label: Text(
                          'Mark Read',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _selectedNotifications.isEmpty
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedNotifications.isEmpty
                            ? null
                            : _deleteSelected,
                        icon: CustomIconWidget(
                          iconName: 'delete',
                          color: _selectedNotifications.isEmpty
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : AppTheme.onPrimary,
                          size: 4.w,
                        ),
                        label: Text(
                          'Delete',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _selectedNotifications.isEmpty
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : AppTheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedNotifications.isEmpty
                              ? colorScheme.surface
                              : AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationDetailWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final VoidCallback? onMarkAsRead;

  const NotificationDetailWidget({
    super.key,
    required this.notification,
    this.onClose,
    this.onShare,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !(notification['isRead'] as bool? ?? false);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onClose?.call();
            Navigator.of(context).pop();
          },
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            color: colorScheme.onSurface,
            size: 5.w,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          'Notification Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isUnread)
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onMarkAsRead?.call();
              },
              icon: CustomIconWidget(
                iconName: 'mark_email_read',
                color: AppTheme.primary,
                size: 5.w,
              ),
              tooltip: 'Mark as read',
            ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onShare?.call();
            },
            icon: CustomIconWidget(
              iconName: 'share',
              color: colorScheme.onSurface,
              size: 5.w,
            ),
            tooltip: 'Share',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type and status row
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(
                                  notification['type'] as String? ?? 'general')
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: _getNotificationIcon(
                                  notification['type'] as String? ?? 'general'),
                              color: _getNotificationColor(
                                  notification['type'] as String? ?? 'general'),
                              size: 3.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              _getNotificationTypeLabel(
                                  notification['type'] as String? ?? 'general'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getNotificationColor(
                                    notification['type'] as String? ??
                                        'general'),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isUnread)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'UNREAD',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Title
                  Text(
                    notification['title'] as String? ?? 'Notification',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Timestamp
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'access_time',
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _formatDetailTimestamp(
                            notification['timestamp'] as String? ?? ''),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Message content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    notification['message'] as String? ??
                        'No message content available.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Sender information (if available)
            if (notification['sender'] != null) ...[
              SizedBox(height: 3.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: AppTheme.primary,
                          size: 6.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            notification['sender'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (if applicable)
            if (notification['actions'] != null) ...[
              SizedBox(height: 3.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ..._buildActionButtons(context,
                        notification['actions'] as List<dynamic>? ?? []),
                  ],
                ),
              ),
            ],

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
      BuildContext context, List<dynamic> actions) {
    return actions.map((action) {
      final actionMap = action as Map<String, dynamic>;
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 2.h),
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Handle action
            Navigator.pushNamed(
                context, actionMap['route'] as String? ?? '/dashboard');
          },
          icon: CustomIconWidget(
            iconName: actionMap['icon'] as String? ?? 'arrow_forward',
            color: AppTheme.onPrimary,
            size: 4.w,
          ),
          label: Text(
            actionMap['label'] as String? ?? 'Action',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onPrimary,
                ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'attendance':
        return 'access_time';
      case 'leave':
        return 'event_available';
      case 'schedule':
        return 'schedule';
      case 'system':
        return 'settings';
      case 'announcement':
        return 'campaign';
      default:
        return 'notifications';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'attendance':
        return AppTheme.primary;
      case 'leave':
        return AppTheme.success;
      case 'schedule':
        return AppTheme.warning;
      case 'system':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'announcement':
        return AppTheme.primary;
      default:
        return AppTheme.lightTheme.colorScheme.onSurface;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'attendance':
        return 'Attendance';
      case 'leave':
        return 'Leave Request';
      case 'schedule':
        return 'Schedule';
      case 'system':
        return 'System';
      case 'announcement':
        return 'Announcement';
      default:
        return 'General';
    }
  }

  String _formatDetailTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago at ${_formatTime(dateTime)}';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

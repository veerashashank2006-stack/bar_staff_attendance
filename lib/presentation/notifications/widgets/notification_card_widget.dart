import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isMultiSelectMode;
  final ValueChanged<bool?>? onSelectionChanged;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !(notification['isRead'] as bool? ?? false);

    return Dismissible(
      key: Key('notification_${notification['id']}'),
      background: _buildSwipeBackground(context, true),
      secondaryBackground: _buildSwipeBackground(context, false),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead?.call();
        } else {
          onDelete?.call();
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (isMultiSelectMode) {
                onSelectionChanged?.call(!isSelected);
              } else {
                onTap?.call();
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onSelectionChanged?.call(!isSelected);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Selection checkbox (multi-select mode)
                  if (isMultiSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: onSelectionChanged,
                      activeColor: AppTheme.primary,
                    ),
                    SizedBox(width: 3.w),
                  ],

                  // Notification icon
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(
                              notification['type'] as String? ?? 'general')
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: _getNotificationIcon(
                            notification['type'] as String? ?? 'general'),
                        color: _getNotificationColor(
                            notification['type'] as String? ?? 'general'),
                        size: 6.w,
                      ),
                    ),
                  ),

                  SizedBox(width: 4.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'] as String? ??
                                    'Notification',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                width: 2.w,
                                height: 2.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(1.w),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          notification['message'] as String? ??
                              'No message content',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'access_time',
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 3.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              _formatTimestamp(
                                  notification['timestamp'] as String? ?? ''),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action indicator
                  if (!isMultiSelectMode)
                    CustomIconWidget(
                      iconName: 'chevron_right',
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 5.w,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, bool isMarkAsRead) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isMarkAsRead ? AppTheme.success : AppTheme.error;
    final icon = isMarkAsRead ? 'mark_email_read' : 'delete';
    final text = isMarkAsRead ? 'Mark as Read' : 'Delete';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: isMarkAsRead ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: icon,
                color: color,
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationEmptyStateWidget extends StatelessWidget {
  final String filterType;

  const NotificationEmptyStateWidget({
    super.key,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _getEmptyStateIcon(),
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20.w,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              _getEmptyStateTitle(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Text(
              _getEmptyStateDescription(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action button (if applicable)
            if (_shouldShowActionButton())
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to relevant section
                  Navigator.pushNamed(context, '/dashboard');
                },
                icon: CustomIconWidget(
                  iconName: 'dashboard',
                  color: AppTheme.onPrimary,
                  size: 4.w,
                ),
                label: Text(
                  'Go to Dashboard',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateIcon() {
    switch (filterType.toLowerCase()) {
      case 'unread':
        return 'mark_email_read';
      case 'attendance':
        return 'access_time';
      case 'leave':
        return 'event_available';
      case 'schedule':
        return 'schedule';
      case 'system':
        return 'settings';
      default:
        return 'notifications_none';
    }
  }

  String _getEmptyStateTitle() {
    switch (filterType.toLowerCase()) {
      case 'unread':
        return 'All Caught Up!';
      case 'attendance':
        return 'No Attendance Alerts';
      case 'leave':
        return 'No Leave Updates';
      case 'schedule':
        return 'No Schedule Changes';
      case 'system':
        return 'No System Notifications';
      default:
        return 'No Notifications Yet';
    }
  }

  String _getEmptyStateDescription() {
    switch (filterType.toLowerCase()) {
      case 'unread':
        return 'You\'ve read all your notifications. Great job staying on top of things!';
      case 'attendance':
        return 'No attendance-related notifications at the moment. Keep up the good work!';
      case 'leave':
        return 'No leave request updates right now. Check back later for status changes.';
      case 'schedule':
        return 'Your schedule is stable with no recent changes or updates.';
      case 'system':
        return 'No system announcements or updates at this time.';
      default:
        return 'When you receive notifications, they\'ll appear here. Check back later!';
    }
  }

  bool _shouldShowActionButton() {
    return filterType.toLowerCase() == 'all';
  }
}

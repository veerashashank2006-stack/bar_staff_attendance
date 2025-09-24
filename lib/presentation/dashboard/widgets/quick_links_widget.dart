import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickLinksWidget extends StatelessWidget {
  final VoidCallback? onAttendanceReportsTap;
  final VoidCallback? onLeaveBalanceTap;

  const QuickLinksWidget({
    super.key,
    this.onAttendanceReportsTap,
    this.onLeaveBalanceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 90.w,
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Links',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickLinkCard(
                  context,
                  'Attendance Reports',
                  'View your attendance history',
                  Icons.assessment_outlined,
                  AppTheme.primary,
                  () {
                    HapticFeedback.lightImpact();
                    if (onAttendanceReportsTap != null) {
                      onAttendanceReportsTap!();
                    } else {
                      Navigator.pushNamed(context, '/attendance-reports');
                    }
                  },
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildQuickLinkCard(
                  context,
                  'Leave Balance',
                  'Check your leave status',
                  Icons.event_note_outlined,
                  AppTheme.warning,
                  () {
                    HapticFeedback.lightImpact();
                    if (onLeaveBalanceTap != null) {
                      onLeaveBalanceTap!();
                    } else {
                      Navigator.pushNamed(context, '/leave-request');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: icon.codePoint.toString(),
                color: accentColor,
                size: 24,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AttendanceTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> attendanceData;
  final Function(Map<String, dynamic>) onViewDetails;
  final Function(Map<String, dynamic>) onExportSingleDay;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const AttendanceTableWidget({
    super.key,
    required this.attendanceData,
    required this.onViewDetails,
    required this.onExportSingleDay,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return _buildSkeletonLoader(colorScheme);
    }

    if (attendanceData.isEmpty) {
      return _buildEmptyState(context, colorScheme, theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildTableHeader(colorScheme, theme),
            ...attendanceData.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return _buildTableRow(
                context,
                record,
                index,
                colorScheme,
                theme,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Login',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Logout',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Hours',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    Map<String, dynamic> record,
    int index,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isEven = index % 2 == 0;

    return Slidable(
      key: ValueKey(record['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.lightImpact();
              onViewDetails(record);
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.visibility,
            label: 'View',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.lightImpact();
              onExportSingleDay(record);
            },
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: Icons.download,
            label: 'Export',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isEven
              ? colorScheme.surface
              : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                record['date'] as String? ?? '--',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                record['login'] as String? ?? '--',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                record['logout'] as String? ?? '--',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                record['hours'] as String? ?? '--',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildStatusChip(
                record['status'] as String? ?? 'Unknown',
                colorScheme,
                theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String status, ColorScheme colorScheme, ThemeData theme) {
    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'present':
        chipColor = AppTheme.success.withValues(alpha: 0.1);
        textColor = AppTheme.success;
        break;
      case 'absent':
        chipColor = colorScheme.error.withValues(alpha: 0.1);
        textColor = colorScheme.error;
        break;
      case 'late':
        chipColor = AppTheme.warning.withValues(alpha: 0.1);
        textColor = AppTheme.warning;
        break;
      case 'partial':
        chipColor = AppTheme.warning.withValues(alpha: 0.1);
        textColor = AppTheme.warning;
        break;
      default:
        chipColor = colorScheme.surface;
        textColor = colorScheme.onSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 10.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSkeletonLoader(ColorScheme colorScheme) {
    return Column(
      children: List.generate(
          8,
          (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: _buildSkeletonBox(20.w, 2.h, colorScheme)),
                    SizedBox(width: 2.w),
                    Expanded(
                        flex: 2,
                        child: _buildSkeletonBox(15.w, 2.h, colorScheme)),
                    SizedBox(width: 2.w),
                    Expanded(
                        flex: 2,
                        child: _buildSkeletonBox(15.w, 2.h, colorScheme)),
                    SizedBox(width: 2.w),
                    Expanded(
                        flex: 1,
                        child: _buildSkeletonBox(10.w, 2.h, colorScheme)),
                    SizedBox(width: 2.w),
                    Expanded(
                        flex: 1,
                        child: _buildSkeletonBox(15.w, 2.h, colorScheme)),
                  ],
                ),
              )),
    );
  }

  Widget _buildSkeletonBox(
      double width, double height, ColorScheme colorScheme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'event_busy',
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            size: 64,
          ),
          SizedBox(height: 3.h),
          Text(
            'No Attendance Records',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'No attendance data found for the selected date range. Try adjusting your filters or check back later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (onRefresh != null) {
                onRefresh!();
              }
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

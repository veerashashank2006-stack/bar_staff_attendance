import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;

  const NotificationFilterWidget({
    super.key,
    required this.selectedFilter,
    this.onFilterChanged,
  });

  static const List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'All', 'icon': 'notifications'},
    {'value': 'unread', 'label': 'Unread', 'icon': 'mark_email_unread'},
    {'value': 'attendance', 'label': 'Attendance', 'icon': 'access_time'},
    {'value': 'leave', 'label': 'Leave', 'icon': 'event_available'},
    {'value': 'schedule', 'label': 'Schedule', 'icon': 'schedule'},
    {'value': 'system', 'label': 'System', 'icon': 'settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 12.h,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => SizedBox(width: 3.w),
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = selectedFilter == filter['value'];

          return _buildFilterChip(
            context,
            filter,
            isSelected,
            colorScheme,
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    Map<String, dynamic> filter,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onFilterChanged?.call(filter['value'] as String);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: filter['icon'] as String,
              color: isSelected
                  ? AppTheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              filter['label'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppTheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

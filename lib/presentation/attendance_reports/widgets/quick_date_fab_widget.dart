import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickDateFabWidget extends StatelessWidget {
  final Function(DateTime, DateTime) onDateRangeSelected;

  const QuickDateFabWidget({
    super.key,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton(
      onPressed: () => _showQuickDateOptions(context),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      child: CustomIconWidget(
        iconName: 'calendar_today',
        color: colorScheme.onPrimary,
        size: 24,
      ),
    );
  }

  void _showQuickDateOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                margin: EdgeInsets.only(top: 2.h),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Date Ranges',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _buildQuickOption(
                      context,
                      'This Week',
                      Icons.view_week,
                      () => _selectThisWeek(context),
                      colorScheme,
                      theme,
                    ),
                    _buildQuickOption(
                      context,
                      'Last Week',
                      Icons.last_page,
                      () => _selectLastWeek(context),
                      colorScheme,
                      theme,
                    ),
                    _buildQuickOption(
                      context,
                      'This Month',
                      Icons.calendar_month,
                      () => _selectThisMonth(context),
                      colorScheme,
                      theme,
                    ),
                    _buildQuickOption(
                      context,
                      'Last Month',
                      Icons.navigate_before,
                      () => _selectLastMonth(context),
                      colorScheme,
                      theme,
                    ),
                    _buildQuickOption(
                      context,
                      'Last 30 Days',
                      Icons.date_range,
                      () => _selectLast30Days(context),
                      colorScheme,
                      theme,
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: icon.toString().split('.').last,
          color: colorScheme.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          onTap();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: colorScheme.surface,
        hoverColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  void _selectThisWeek(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    onDateRangeSelected(startOfWeek, endOfWeek);
  }

  void _selectLastWeek(BuildContext context) {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
    onDateRangeSelected(startOfLastWeek, endOfLastWeek);
  }

  void _selectThisMonth(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    onDateRangeSelected(startOfMonth, endOfMonth);
  }

  void _selectLastMonth(BuildContext context) {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    onDateRangeSelected(startOfLastMonth, endOfLastMonth);
  }

  void _selectLast30Days(BuildContext context) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    onDateRangeSelected(thirtyDaysAgo, now);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationSearchBarWidget extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;

  const NotificationSearchBarWidget({
    super.key,
    this.initialQuery,
    this.onSearchChanged,
    this.onClear,
  });

  @override
  State<NotificationSearchBarWidget> createState() =>
      _NotificationSearchBarWidgetState();
}

class _NotificationSearchBarWidgetState
    extends State<NotificationSearchBarWidget> {
  late TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _isSearchActive = (widget.initialQuery?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchActive
              ? AppTheme.primary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _isSearchActive = value.isNotEmpty;
          });
          widget.onSearchChanged?.call(value);
        },
        onTap: () {
          HapticFeedback.lightImpact();
        },
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: _isSearchActive
                  ? AppTheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.5),
              size: 5.w,
            ),
          ),
          suffixIcon: _isSearchActive
              ? IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                    setState(() {
                      _isSearchActive = false;
                    });
                    widget.onClear?.call();
                    widget.onSearchChanged?.call('');
                  },
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 5.w,
                  ),
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 3.h,
          ),
        ),
      ),
    );
  }
}

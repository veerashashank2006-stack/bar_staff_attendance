import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tab item data class for custom tab bar
class TabItem {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final String? route;

  const TabItem({
    required this.label,
    this.icon,
    this.customIcon,
    this.route,
  });
}

/// Custom tab bar with glassmorphism effect and professional styling
/// Implements the Contemporary Minimalist Professional design with dark-first approach
class CustomTabBar extends StatelessWidget {
  final List<TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final double height;
  final EdgeInsets padding;
  final bool isScrollable;
  final TabAlignment tabAlignment;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.isScrollable = false,
    this.tabAlignment = TabAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        tabs: tabs.map((tab) => _buildTab(context, tab, colorScheme)).toList(),
        controller: null, // Let parent handle controller
        isScrollable: isScrollable,
        tabAlignment: tabAlignment,
        labelColor: selectedColor ?? colorScheme.primary,
        unselectedLabelColor:
            unselectedColor ?? colorScheme.onSurface.withAlpha(153),
        indicatorColor: indicatorColor ?? colorScheme.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!(index);
          } else if (tabs[index].route != null) {
            Navigator.pushNamed(context, tabs[index].route!);
          }
        },
      ),
    );
  }

  Widget _buildTab(BuildContext context, TabItem tab, ColorScheme colorScheme) {
    if (tab.icon != null || tab.customIcon != null) {
      return Tab(
        icon: tab.customIcon ?? Icon(tab.icon, size: 20),
        text: tab.label,
        iconMargin: const EdgeInsets.only(bottom: 4),
      );
    }

    return Tab(text: tab.label);
  }
}

/// Segmented tab bar for reports and analytics sections
class CustomSegmentedTabBar extends StatelessWidget {
  final List<TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double height;
  final EdgeInsets margin;
  final double borderRadius;

  const CustomSegmentedTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.height = 40,
    this.margin = const EdgeInsets.all(16),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == currentIndex;
          final isFirst = index == 0;
          final isLast = index == tabs.length - 1;

          return Expanded(
            child: _buildSegmentedTab(
              context,
              tab,
              index,
              isSelected,
              isFirst,
              isLast,
              colorScheme,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSegmentedTab(
    BuildContext context,
    TabItem tab,
    int index,
    bool isSelected,
    bool isFirst,
    bool isLast,
    ColorScheme colorScheme,
  ) {
    final selectedBgColor = selectedColor ?? colorScheme.primary;
    final selectedTextColor = colorScheme.onPrimary;
    final unselectedTextColor =
        unselectedColor ?? colorScheme.onSurface.withAlpha(179);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!(index);
        } else if (tab.route != null) {
          Navigator.pushNamed(context, tab.route!);
        }
      },
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? Radius.circular(borderRadius - 1) : Radius.zero,
        right: isLast ? Radius.circular(borderRadius - 1) : Radius.zero,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? Radius.circular(borderRadius - 1) : Radius.zero,
            right: isLast ? Radius.circular(borderRadius - 1) : Radius.zero,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.icon != null || tab.customIcon != null) ...[
                tab.customIcon ??
                    Icon(
                      tab.icon,
                      size: 16,
                      color:
                          isSelected ? selectedTextColor : unselectedTextColor,
                    ),
                const SizedBox(width: 6),
              ],
              Text(
                tab.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Specialized tab bar for attendance reports with predefined tabs
class CustomReportsTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  // Hardcoded tabs for attendance reports
  static const List<TabItem> _reportTabs = [
    TabItem(
      label: 'Daily',
      icon: Icons.today_outlined,
    ),
    TabItem(
      label: 'Weekly',
      icon: Icons.view_week_outlined,
    ),
    TabItem(
      label: 'Monthly',
      icon: Icons.calendar_month_outlined,
    ),
    TabItem(
      label: 'Summary',
      icon: Icons.analytics_outlined,
    ),
  ];

  const CustomReportsTabBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTabBar(
      tabs: _reportTabs,
      currentIndex: currentIndex,
      onTap: onTap,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
    );
  }
}

/// Specialized tab bar for leave request status with predefined tabs
class CustomLeaveTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  // Hardcoded tabs for leave requests
  static const List<TabItem> _leaveTabs = [
    TabItem(
      label: 'Pending',
      icon: Icons.pending_outlined,
    ),
    TabItem(
      label: 'Approved',
      icon: Icons.check_circle_outlined,
    ),
    TabItem(
      label: 'Rejected',
      icon: Icons.cancel_outlined,
    ),
    TabItem(
      label: 'History',
      icon: Icons.history_outlined,
    ),
  ];

  const CustomLeaveTabBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSegmentedTabBar(
      tabs: _leaveTabs,
      currentIndex: currentIndex,
      onTap: onTap,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 22,
    );
  }
}

/// Pill-style tab bar for settings sections
class CustomPillTabBar extends StatelessWidget {
  final List<TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsets padding;
  final double spacing;

  const CustomPillTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: padding,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == currentIndex;

          return _buildPillTab(
            context,
            tab,
            index,
            isSelected,
            colorScheme,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPillTab(
    BuildContext context,
    TabItem tab,
    int index,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    final selectedBgColor = selectedColor ?? colorScheme.primary;
    final selectedTextColor = colorScheme.onPrimary;
    final unselectedBgColor = backgroundColor ?? colorScheme.surface;
    final unselectedTextColor =
        unselectedColor ?? colorScheme.onSurface.withAlpha(179);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!(index);
        } else if (tab.route != null) {
          Navigator.pushNamed(context, tab.route!);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedBgColor
                : colorScheme.outline.withAlpha(77),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.icon != null || tab.customIcon != null) ...[
              tab.customIcon ??
                  Icon(
                    tab.icon,
                    size: 16,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                  ),
              const SizedBox(width: 6),
            ],
            Text(
              tab.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? selectedTextColor : unselectedTextColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

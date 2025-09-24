import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Add this import for ImageFilter

/// Navigation item data class for bottom navigation
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String route;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Custom bottom navigation bar with glassmorphism effect and professional styling
/// Implements the Contemporary Minimalist Professional design with dark-first approach
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;

  // Hardcoded navigation items for employee attendance management
  static const List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    BottomNavItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'Scanner',
      route: '/qr-scanner',
    ),
    BottomNavItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'Reports',
      route: '/attendance-reports',
    ),
    BottomNavItem(
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Leave',
      route: '/leave-request',
    ),
  ];

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withAlpha(51),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return _buildNavItem(
                context,
                item,
                index,
                isSelected,
                colorScheme,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    BottomNavItem item,
    int index,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor =
        unselectedItemColor ?? colorScheme.onSurface.withAlpha(153);

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!(index);
          } else {
            Navigator.pushNamed(context, item.route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with selection indicator
              Container(
                padding: const EdgeInsets.all(4),
                decoration: isSelected
                    ? BoxDecoration(
                        color: selectedColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 24,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get the current route based on the selected index
  static String getRouteForIndex(int index) {
    if (index >= 0 && index < _navItems.length) {
      return _navItems[index].route;
    }
    return '/dashboard';
  }

  /// Get the index for a given route
  static int getIndexForRoute(String route) {
    for (int i = 0; i < _navItems.length; i++) {
      if (_navItems[i].route == route) {
        return i;
      }
    }
    return 0; // Default to dashboard
  }
}

/// Floating bottom navigation bar variant with enhanced glassmorphism
class CustomFloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double borderRadius;
  final EdgeInsets margin;

  const CustomFloatingBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.borderRadius = 24,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? colorScheme.surface).withAlpha(230),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: colorScheme.outline.withAlpha(51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 64,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:
                      CustomBottomBar._navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == currentIndex;

                    return _buildFloatingNavItem(
                      context,
                      item,
                      index,
                      isSelected,
                      colorScheme,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(
    BuildContext context,
    BottomNavItem item,
    int index,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor =
        unselectedItemColor ?? colorScheme.onSurface.withAlpha(153);

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!(index);
          } else {
            Navigator.pushNamed(context, item.route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with enhanced selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(6),
                decoration: isSelected
                    ? BoxDecoration(
                        color: selectedColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 22,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 2),
              // Label with animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                  letterSpacing: 0.4,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
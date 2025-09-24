import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DashboardDrawerWidget extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String currentRoute;
  final VoidCallback? onLogout;

  const DashboardDrawerWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.currentRoute,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // User Avatar
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: userAvatar != null
                          ? CustomImageWidget(
                              imageUrl: userAvatar!,
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              child: CustomIconWidget(
                                iconName: Icons.person.codePoint.toString(),
                                color: AppTheme.primary,
                                size: 10.w,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // User Info
                  Text(
                    userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                children: [
                  _buildNavItem(
                    context,
                    'Dashboard',
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    '/dashboard',
                  ),
                  _buildNavItem(
                    context,
                    'Scanner',
                    Icons.qr_code_scanner_outlined,
                    Icons.qr_code_scanner,
                    '/qr-scanner',
                  ),
                  _buildNavItem(
                    context,
                    'Reports',
                    Icons.assessment_outlined,
                    Icons.assessment,
                    '/attendance-reports',
                  ),
                  _buildNavItem(
                    context,
                    'Leave Requests',
                    Icons.event_note_outlined,
                    Icons.event_note,
                    '/leave-request',
                  ),
                  _buildNavItem(
                    context,
                    'Notifications',
                    Icons.notifications_outlined,
                    Icons.notifications,
                    '/notifications',
                  ),
                  _buildNavItem(
                    context,
                    'Settings',
                    Icons.settings_outlined,
                    Icons.settings,
                    '/settings',
                  ),
                ],
              ),
            ),

            // Logout
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _buildLogoutItem(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    IconData activeIcon,
    String route,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = currentRoute == route;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      child: ListTile(
        leading: CustomIconWidget(
          iconName: (isActive ? activeIcon : icon).codePoint.toString(),
          color: isActive
              ? AppTheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.7),
          size: 24,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? AppTheme.primary : colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isActive,
        selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          if (!isActive) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CustomIconWidget(
        iconName: Icons.logout.codePoint.toString(),
        color: AppTheme.error,
        size: 24,
      ),
      title: Text(
        'Logout',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Logout',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onLogout != null) {
                  onLogout!();
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login-screen',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Logout',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

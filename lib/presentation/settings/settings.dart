import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/change_password_dialog.dart';
import './widgets/profile_section_widget.dart';
import './widgets/settings_section_widget.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Sarah Johnson",
    "employeeId": "EMP001",
    "profileImage":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face",
    "email": "sarah.johnson@barstaff.com",
    "phone": "+1 (555) 123-4567",
    "department": "Bar Operations",
    "position": "Senior Bartender"
  };

  // Settings state
  bool _isDarkMode = true;
  bool _pushNotifications = true;
  bool _emailAlerts = false;
  bool _attendanceReminders = true;
  bool _leaveNotifications = true;
  bool _biometricAuth = false;
  int _sessionTimeout = 30; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
            AppTheme.darkTheme.colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back_ios',
            size: 5.w,
            color: AppTheme.darkTheme.colorScheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Profile Section
            ProfileSectionWidget(
              userName: _userData["name"] as String,
              employeeId: _userData["employeeId"] as String,
              profileImageUrl: _userData["profileImage"] as String?,
              onNameChanged: (newName) {
                setState(() {
                  _userData["name"] = newName;
                });
                _showSuccessMessage('Name updated successfully');
              },
              onImageChanged: (imagePath) {
                setState(() {
                  _userData["profileImage"] =
                      imagePath.isEmpty ? null : imagePath;
                });
                if (imagePath.isNotEmpty) {
                  _showSuccessMessage('Profile picture updated successfully');
                }
              },
            ),

            SizedBox(height: 2.h),

            // Account Section
            SettingsSectionWidget(
              title: 'ACCOUNT',
              items: [
                SettingsItem(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  icon: 'lock',
                  onTap: _showChangePasswordDialog,
                ),
                SettingsItem(
                  title: 'Email',
                  subtitle: _userData["email"] as String,
                  icon: 'email',
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Phone',
                  subtitle: _userData["phone"] as String,
                  icon: 'phone',
                  showDisclosure: false,
                ),
              ],
            ),

            // App Preferences Section
            SettingsSectionWidget(
              title: 'APP PREFERENCES',
              items: [
                SettingsItem(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme throughout the app',
                  icon: 'dark_mode',
                  hasSwitch: true,
                  switchValue: _isDarkMode,
                  onSwitchChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    HapticFeedback.lightImpact();
                    _showSuccessMessage(
                        'Theme ${value ? 'Dark' : 'Light'} mode enabled');
                  },
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Session Timeout',
                  subtitle:
                      'Auto-logout after $_sessionTimeout minutes of inactivity',
                  icon: 'timer',
                  onTap: _showSessionTimeoutDialog,
                ),
              ],
            ),

            // Notification Preferences Section
            SettingsSectionWidget(
              title: 'NOTIFICATIONS',
              items: [
                SettingsItem(
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  icon: 'notifications',
                  hasSwitch: true,
                  switchValue: _pushNotifications,
                  onSwitchChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Email Alerts',
                  subtitle: 'Receive important updates via email',
                  icon: 'mail',
                  hasSwitch: true,
                  switchValue: _emailAlerts,
                  onSwitchChanged: (value) {
                    setState(() {
                      _emailAlerts = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Attendance Reminders',
                  subtitle: 'Get reminded to clock in/out',
                  icon: 'schedule',
                  hasSwitch: true,
                  switchValue: _attendanceReminders,
                  onSwitchChanged: (value) {
                    setState(() {
                      _attendanceReminders = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Leave Notifications',
                  subtitle: 'Updates on leave request status',
                  icon: 'event_note',
                  hasSwitch: true,
                  switchValue: _leaveNotifications,
                  onSwitchChanged: (value) {
                    setState(() {
                      _leaveNotifications = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                  showDisclosure: false,
                ),
              ],
            ),

            // Security Section
            SettingsSectionWidget(
              title: 'SECURITY',
              items: [
                SettingsItem(
                  title: 'Biometric Authentication',
                  subtitle: 'Use Face ID or Fingerprint to unlock',
                  icon: 'fingerprint',
                  hasSwitch: true,
                  switchValue: _biometricAuth,
                  onSwitchChanged: (value) {
                    setState(() {
                      _biometricAuth = value;
                    });
                    HapticFeedback.lightImpact();
                    _showSuccessMessage(
                        'Biometric authentication ${value ? 'enabled' : 'disabled'}');
                  },
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  icon: 'privacy_tip',
                  onTap: () => _openWebPage(
                      'Privacy Policy', 'https://example.com/privacy'),
                ),
                SettingsItem(
                  title: 'Terms of Service',
                  subtitle: 'Read our terms of service',
                  icon: 'description',
                  onTap: () => _openWebPage(
                      'Terms of Service', 'https://example.com/terms'),
                ),
              ],
            ),

            // About Section
            SettingsSectionWidget(
              title: 'ABOUT',
              items: [
                SettingsItem(
                  title: 'App Version',
                  subtitle: '1.0.0 (Build 100)',
                  icon: 'info',
                  showDisclosure: false,
                ),
                SettingsItem(
                  title: 'Help & Support',
                  subtitle: 'Get help or contact support',
                  icon: 'help',
                  onTap: () => _openWebPage(
                      'Help & Support', 'https://example.com/support'),
                ),
                SettingsItem(
                  title: 'Rate App',
                  subtitle: 'Rate us on the App Store',
                  icon: 'star',
                  onTap: _rateApp,
                ),
              ],
            ),

            // Logout Section
            SettingsSectionWidget(
              title: 'ACCOUNT ACTIONS',
              items: [
                SettingsItem(
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  icon: 'logout',
                  iconColor: AppTheme.darkTheme.colorScheme.error,
                  isDestructive: true,
                  onTap: _showLogoutDialog,
                  showDisclosure: false,
                ),
              ],
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showSessionTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        title: Text(
          'Session Timeout',
          style: AppTheme.darkTheme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select auto-logout time:',
              style: AppTheme.darkTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            ...([15, 30, 60, 120].map((minutes) => RadioListTile<int>(
                  title: Text(
                    '$minutes minutes',
                    style: AppTheme.darkTheme.textTheme.bodyMedium,
                  ),
                  value: minutes,
                  groupValue: _sessionTimeout,
                  activeColor: AppTheme.primary,
                  onChanged: (value) {
                    setState(() {
                      _sessionTimeout = value!;
                    });
                    Navigator.pop(context);
                    _showSuccessMessage(
                        'Session timeout updated to $value minutes');
                  },
                ))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        title: Text(
          'Logout',
          style: AppTheme.darkTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: AppTheme.darkTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppTheme.darkTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    HapticFeedback.lightImpact();
    // Clear user session and navigate to login
    Navigator.pushNamedAndRemoveUntil(
        context, '/login-screen', (route) => false);
  }

  void _openWebPage(String title, String url) {
    // In a real app, this would open a web browser or in-app browser
    _showSuccessMessage('Opening $title...');
  }

  void _rateApp() {
    // In a real app, this would open the app store rating page
    _showSuccessMessage('Opening App Store...');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/attendance_card_widget.dart';
import './widgets/dashboard_drawer_widget.dart';
import './widgets/quick_links_widget.dart';
import './widgets/recent_activity_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  bool _isOnline = true;
  DateTime _lastSyncTime = DateTime.now();

  // Mock user data
  final Map<String, dynamic> _userData = {
    "id": "EMP001",
    "name": "Sarah Johnson",
    "email": "sarah.johnson@barstaff.com",
    "avatar":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face",
    "role": "Bartender",
    "department": "Bar Operations"
  };

  // Mock attendance data
  Map<String, dynamic> _attendanceData = {
    "loginTime": "9:15 AM",
    "logoutTime": null,
    "hoursWorked": "4h 23m",
    "status": "Clocked In",
    "date": "2025-09-23",
    "isLate": false
  };

  // Mock recent activities
  final List<Map<String, dynamic>> _recentActivities = [
    {
      "id": 1,
      "type": "clock_in",
      "description": "Clocked in for morning shift",
      "timestamp": "Today, 9:15 AM",
      "status": "completed",
      "location": "Main Bar"
    },
    {
      "id": 2,
      "type": "leave_approved",
      "description": "Annual leave request approved",
      "timestamp": "Yesterday, 3:30 PM",
      "status": "approved",
      "duration": "2 days"
    },
    {
      "id": 3,
      "type": "clock_out",
      "description": "Clocked out from evening shift",
      "timestamp": "Yesterday, 11:45 PM",
      "status": "completed",
      "location": "Main Bar"
    },
    {
      "id": 4,
      "type": "leave_request",
      "description": "Sick leave request submitted",
      "timestamp": "Sep 21, 2:15 PM",
      "status": "pending",
      "duration": "1 day"
    },
    {
      "id": 5,
      "type": "clock_in",
      "description": "Clocked in for weekend shift",
      "timestamp": "Sep 21, 6:00 PM",
      "status": "completed",
      "location": "Rooftop Bar"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Simulate data loading and sync
      await Future.delayed(const Duration(milliseconds: 800));

      // Check connectivity and sync data
      await _syncDataWithServer();

      setState(() {
        _isLoading = false;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOnline = false;
      });
    }
  }

  Future<void> _syncDataWithServer() async {
    try {
      // Simulate API call to sync attendance data
      await Future.delayed(const Duration(milliseconds: 500));

      // Update attendance data with latest info
      setState(() {
        _isOnline = true;
        _lastSyncTime = DateTime.now();
      });

      // Show sync success with haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _isOnline = false);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _syncDataWithServer();

    // Update attendance hours worked simulation
    final currentHours =
        int.parse(_attendanceData['hoursWorked'].toString().split('h')[0]);
    final currentMinutes = int.parse(_attendanceData['hoursWorked']
        .toString()
        .split('h')[1]
        .split('m')[0]
        .trim());
    final newMinutes = currentMinutes + 1;

    setState(() {
      if (newMinutes >= 60) {
        _attendanceData['hoursWorked'] = '${currentHours + 1}h 0m';
      } else {
        _attendanceData['hoursWorked'] = '${currentHours}h ${newMinutes}m';
      }
    });
  }

  void _onQuickScanTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/qr-scanner');
  }

  void _onAttendanceReportsTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/attendance-reports');
  }

  void _onLeaveBalanceTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/leave-request');
  }

  void _onLogout() {
    HapticFeedback.mediumImpact();
    // Clear any stored data and navigate to login
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login-screen',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      drawer: DashboardDrawerWidget(
        userName: _userData['name'] as String,
        userEmail: _userData['email'] as String,
        userAvatar: _userData['avatar'] as String?,
        currentRoute: '/dashboard',
        onLogout: _onLogout,
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: AppTheme.primary,
        backgroundColor: colorScheme.surface,
        child: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 4,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: Icons.menu.codePoint.toString(),
          color: colorScheme.onSurface,
          size: 24,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            _userData['name'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // Sync Status Indicator
        Container(
          margin: EdgeInsets.only(right: 2.w),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isOnline ? AppTheme.success : AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 1.w),
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _isOnline ? AppTheme.success : AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Notifications
        IconButton(
          icon: CustomIconWidget(
            iconName: Icons.notifications_outlined.codePoint.toString(),
            color: colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 80.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: 3.h),
              Text(
                'Loading Dashboard...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),

          // Sync Status Banner (if offline)
          if (!_isOnline) _buildOfflineBanner(),

          // Today's Attendance Card
          AttendanceCardWidget(
            attendanceData: _attendanceData,
            onTap: _onAttendanceReportsTap,
          ),

          SizedBox(height: 2.h),

          // Quick Links
          QuickLinksWidget(
            onAttendanceReportsTap: _onAttendanceReportsTap,
            onLeaveBalanceTap: _onLeaveBalanceTap,
          ),

          SizedBox(height: 2.h),

          // Recent Activity
          RecentActivityWidget(
            activities: _recentActivities,
          ),

          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: Icons.cloud_off.codePoint.toString(),
            color: AppTheme.warning,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Mode',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Data will sync when connection is restored',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.warning.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _onQuickScanTap,
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.onPrimary,
      elevation: 6,
      icon: CustomIconWidget(
        iconName: Icons.qr_code_scanner.codePoint.toString(),
        color: AppTheme.onPrimary,
        size: 24,
      ),
      label: Text(
        'Quick Scan',
        style: TextStyle(
          color: AppTheme.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

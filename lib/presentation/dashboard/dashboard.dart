import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/attendance_record.dart';
import '../../models/notification.dart';
import '../../models/user_profile.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
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

  bool _isLoading = true;
  bool _isOnline = true;
  DateTime _lastSyncTime = DateTime.now();
  String? _errorMessage;

  // Live data from Supabase
  UserProfile? _userProfile;
  AttendanceRecord? _todayAttendance;
  List<NotificationModel> _recentNotifications = [];
  List<AttendanceRecord> _recentAttendance = [];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      if (!AuthService.isAuthenticated) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
        return;
      }

      // Load user data and dashboard information
      await _loadDashboardData();

      setState(() {
        _isLoading = false;
        _isOnline = true;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOnline = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
      debugPrint('Dashboard initialization error: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load user profile
      _userProfile = await AuthService.getCurrentUserProfile();

      // Load today's attendance
      _todayAttendance = await AttendanceService.getTodayAttendance();

      // Load recent attendance records (last 5)
      _recentAttendance =
          await AttendanceService.getMyAttendanceRecords(limit: 5);

      // Load recent notifications (last 5)
      _recentNotifications =
          await NotificationService.getNotifications(limit: 5);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      throw e;
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();

    try {
      await _loadDashboardData();
      setState(() {
        _isOnline = true;
        _lastSyncTime = DateTime.now();
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
        _errorMessage = 'Sync failed: ${e.toString()}';
      });
    }
  }

  void _onQuickScanTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.qrScanner);
  }

  void _onAttendanceReportsTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.attendanceReports);
  }

  void _onLeaveBalanceTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.leaveRequest);
  }

  void _onLogout() async {
    HapticFeedback.mediumImpact();
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still navigate to login even if logout fails
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  // Convert attendance records to activity format for UI compatibility
  List<Map<String, dynamic>> get _formattedRecentActivities {
    List<Map<String, dynamic>> activities = [];

    // Add attendance records
    for (var record in _recentAttendance) {
      activities.add({
        "id": record.id,
        "type": record.checkInTime != null && record.checkOutTime != null
            ? "clock_out"
            : "clock_in",
        "description": record.checkOutTime != null
            ? "Clocked out - ${record.displayStatus}"
            : "Clocked in - ${record.displayStatus}",
        "timestamp": _formatTimestamp(record.checkInTime ?? record.createdAt),
        "status": "completed",
        "duration": record.formattedWorkingHours,
      });
    }

    // Add recent notifications
    for (var notification in _recentNotifications.take(3)) {
      String type = "info";
      if (notification.type == "success")
        type = "leave_approved";
      else if (notification.type == "warning")
        type = "leave_request";
      else if (notification.title.toLowerCase().contains("leave"))
        type = "leave_request";

      activities.add({
        "id": notification.id,
        "type": type,
        "description": notification.title,
        "timestamp": _formatTimestamp(notification.createdAt),
        "status": notification.type,
        "message": notification.message,
      });
    }

    // Sort by timestamp (most recent first)
    activities.sort((a, b) {
      return _parseTimestamp(b["timestamp"])
          .compareTo(_parseTimestamp(a["timestamp"]));
    });

    return activities.take(5).toList();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return "Today, ${_formatTime(dateTime)}";
    } else if (difference.inDays == 1) {
      return "Yesterday, ${_formatTime(dateTime)}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  DateTime _parseTimestamp(String timestamp) {
    // Simple parsing for sorting - can be improved
    if (timestamp.startsWith("Today")) return DateTime.now();
    if (timestamp.startsWith("Yesterday"))
      return DateTime.now().subtract(const Duration(days: 1));
    return DateTime.now().subtract(const Duration(days: 7)); // Default fallback
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  // Convert today's attendance to widget format
  Map<String, dynamic> get _formattedAttendanceData {
    if (_todayAttendance == null) {
      return {
        "loginTime": null,
        "logoutTime": null,
        "hoursWorked": "0h 0m",
        "status": "Not Clocked In",
        "date": DateTime.now().toString().split(' ')[0],
        "isLate": false
      };
    }

    return {
      "loginTime": _todayAttendance!.checkInTime != null
          ? _formatTime(_todayAttendance!.checkInTime!)
          : null,
      "logoutTime": _todayAttendance!.checkOutTime != null
          ? _formatTime(_todayAttendance!.checkOutTime!)
          : null,
      "hoursWorked": _todayAttendance!.formattedWorkingHours,
      "status": _todayAttendance!.checkOutTime != null
          ? "Clocked Out"
          : (_todayAttendance!.checkInTime != null ? "Clocked In" : "Not Clocked In"),
      "date": _todayAttendance!.date.toString().split(' ')[0],
      "isLate": _todayAttendance!.status == AttendanceStatus.late
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      drawer: _userProfile != null
          ? DashboardDrawerWidget(
              userName: _userProfile!.fullName,
              userEmail: _userProfile!.email,
              userAvatar: _userProfile!.profileImageUrl,
              currentRoute: AppRoutes.dashboard,
              onLogout: _onLogout,
            )
          : null,
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
            _userProfile?.fullName.split(' ').first ?? 'User',
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

        // Notifications with badge
        Stack(
          children: [
            IconButton(
              icon: CustomIconWidget(
                iconName: Icons.notifications_outlined.codePoint.toString(),
                color: colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            ),
            if (_recentNotifications.where((n) => !n.isRead).isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
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
              if (_errorMessage != null) ...[
                SizedBox(height: 2.h),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
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

          // Error Banner (if any)
          if (_errorMessage != null) _buildErrorBanner(),

          // Today's Attendance Card
          AttendanceCardWidget(
            attendanceData: _formattedAttendanceData,
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
            activities: _formattedRecentActivities,
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

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: Icons.error_outline.codePoint.toString(),
            color: AppTheme.error,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Error',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Pull down to refresh and try again',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.error.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: Icons.close.codePoint.toString(),
              color: AppTheme.error,
              size: 16,
            ),
            onPressed: () {
              setState(() => _errorMessage = null);
            },
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
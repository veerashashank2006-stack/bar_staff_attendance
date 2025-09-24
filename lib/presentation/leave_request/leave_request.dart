import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/leave_request_form_widget.dart';
import './widgets/leave_requests_list_widget.dart';

class LeaveRequest extends StatefulWidget {
  const LeaveRequest({super.key});

  @override
  State<LeaveRequest> createState() => _LeaveRequestState();
}

class _LeaveRequestState extends State<LeaveRequest>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomNavIndex = 3; // Leave Request tab index

  // Mock data for leave requests
  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'id': 1,
      'startDate': '2025-01-15T00:00:00.000Z',
      'endDate': '2025-01-17T00:00:00.000Z',
      'reason':
          'Family vacation to celebrate my parents\' wedding anniversary. We have planned this trip for months and all family members will be attending.',
      'days': 3,
      'status': 'Pending',
      'submittedAt': '2025-01-10T09:30:00.000Z',
    },
    {
      'id': 2,
      'startDate': '2024-12-23T00:00:00.000Z',
      'endDate': '2024-12-27T00:00:00.000Z',
      'reason':
          'Christmas holidays with family. Planning to visit my hometown and spend quality time with relatives.',
      'days': 5,
      'status': 'Approved',
      'submittedAt': '2024-12-01T14:20:00.000Z',
    },
    {
      'id': 3,
      'startDate': '2024-11-15T00:00:00.000Z',
      'endDate': '2024-11-16T00:00:00.000Z',
      'reason': 'Medical appointment and recovery time.',
      'days': 2,
      'status': 'Rejected',
      'submittedAt': '2024-11-10T11:45:00.000Z',
    },
    {
      'id': 4,
      'startDate': '2024-10-20T00:00:00.000Z',
      'endDate': '2024-10-22T00:00:00.000Z',
      'reason':
          'Personal matters that require immediate attention. Need to handle some urgent family business.',
      'days': 3,
      'status': 'Approved',
      'submittedAt': '2024-10-15T16:10:00.000Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    HapticFeedback.lightImpact();

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/qr-scanner');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/attendance-reports');
        break;
      case 3:
        // Already on leave request screen
        break;
    }
  }

  void _handleNewRequest(Map<String, dynamic> requestData) {
    setState(() {
      _leaveRequests.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        ...requestData,
      });
    });

    // Switch to My Requests tab to show the new request
    _tabController.animateTo(1);

    _showSnackBar('Leave request submitted successfully!');
  }

  void _handleRequestTap(Map<String, dynamic> request) {
    // Handle request tap - could navigate to details or show modal
    HapticFeedback.lightImpact();
  }

  void _handleCancelRequest(Map<String, dynamic> request) {
    setState(() {
      final index = _leaveRequests.indexWhere((r) => r['id'] == request['id']);
      if (index != -1) {
        _leaveRequests[index]['status'] = 'Cancelled';
      }
    });

    _showSnackBar('Leave request cancelled');
    HapticFeedback.mediumImpact();
  }

  void _handleResubmitRequest(Map<String, dynamic> request) {
    // Create a new request based on the rejected one
    final newRequest = Map<String, dynamic>.from(request);
    newRequest['id'] = DateTime.now().millisecondsSinceEpoch;
    newRequest['status'] = 'Pending';
    newRequest['submittedAt'] = DateTime.now().toIso8601String();

    setState(() {
      _leaveRequests.insert(0, newRequest);
    });

    _showSnackBar('Request resubmitted successfully!');
    HapticFeedback.mediumImpact();
  }

  void _handleRefresh() {
    // Simulate refresh - in real app, this would fetch from API
    HapticFeedback.lightImpact();
    _showSnackBar('Requests updated');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Leave Request',
        centerTitle: true,
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
              HapticFeedback.lightImpact();
            },
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(23),
              ),
              labelColor: AppTheme.onPrimary,
              unselectedLabelColor:
                  colorScheme.onSurface.withValues(alpha: 0.7),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
              onTap: (index) => HapticFeedback.lightImpact(),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'add_circle_outline',
                        color: _tabController.index == 0
                            ? AppTheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      const Text('New Request'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'list_alt',
                        color: _tabController.index == 1
                            ? AppTheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      const Text('My Requests'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // New Request Tab
                LeaveRequestFormWidget(
                  onSubmit: _handleNewRequest,
                ),

                // My Requests Tab
                LeaveRequestsListWidget(
                  requests: _leaveRequests,
                  onRequestTap: _handleRequestTap,
                  onCancelRequest: _handleCancelRequest,
                  onResubmitRequest: _handleResubmitRequest,
                  onRefresh: _handleRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import './leave_request_card_widget.dart';

class LeaveRequestsListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> requests;
  final Function(Map<String, dynamic>) onRequestTap;
  final Function(Map<String, dynamic>) onCancelRequest;
  final Function(Map<String, dynamic>) onResubmitRequest;
  final VoidCallback onRefresh;

  const LeaveRequestsListWidget({
    super.key,
    required this.requests,
    required this.onRequestTap,
    required this.onCancelRequest,
    required this.onResubmitRequest,
    required this.onRefresh,
  });

  @override
  State<LeaveRequestsListWidget> createState() =>
      _LeaveRequestsListWidgetState();
}

class _LeaveRequestsListWidgetState extends State<LeaveRequestsListWidget> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));

    widget.onRefresh();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RequestDetailsSheet(request: request),
    );
  }

  void _showCancelConfirmation(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content:
            const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancelRequest(request);
              HapticFeedback.mediumImpact();
            },
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _sortedRequests {
    final sorted = List<Map<String, dynamic>>.from(widget.requests);
    sorted.sort((a, b) {
      final aDate = DateTime.tryParse(a['submittedAt'] as String? ?? '') ??
          DateTime.now();
      final bDate = DateTime.tryParse(b['submittedAt'] as String? ?? '') ??
          DateTime.now();
      return bDate.compareTo(aDate); // Most recent first
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.requests.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primary,
      backgroundColor: colorScheme.surface,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 1.h, bottom: 10.h),
        itemCount: _sortedRequests.length,
        itemBuilder: (context, index) {
          final request = _sortedRequests[index];
          final status = request['status'] as String;

          return LeaveRequestCardWidget(
            request: request,
            onTap: () => _showRequestDetails(request),
            onViewDetails: () => _showRequestDetails(request),
            onCancel: status.toLowerCase() == 'pending'
                ? () => _showCancelConfirmation(request)
                : null,
            onResubmit: status.toLowerCase() == 'rejected'
                ? () => widget.onResubmitRequest(request)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'event_note',
                  color: AppTheme.primary,
                  size: 12.w,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Leave Requests',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You haven\'t submitted any leave requests yet.\nTap "New Request" to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb_outline',
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Tip: Plan your leave requests in advance for better approval chances',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> request;

  const _RequestDetailsSheet({required this.request});

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.textMediumEmphasis;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = request['status'] as String;
    final statusColor = _getStatusColor(status);

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Request Details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: status.toLowerCase() == 'approved'
                                ? 'check_circle'
                                : status.toLowerCase() == 'rejected'
                                    ? 'cancel'
                                    : 'pending',
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              status,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Date Range
                  _buildDetailRow(
                    context,
                    'Date Range',
                    '${_formatDate(request['startDate'] as String)} - ${_formatDate(request['endDate'] as String)}',
                    Icons.date_range,
                  ),
                  SizedBox(height: 2.h),

                  // Duration
                  _buildDetailRow(
                    context,
                    'Duration',
                    '${request['days']} day${(request['days'] as int) == 1 ? '' : 's'}',
                    Icons.schedule,
                  ),
                  SizedBox(height: 2.h),

                  // Submitted Date
                  _buildDetailRow(
                    context,
                    'Submitted',
                    _formatDate(request['submittedAt'] as String),
                    Icons.send,
                  ),
                  SizedBox(height: 3.h),

                  // Reason
                  Text(
                    'Reason',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      request['reason'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: icon.codePoint.toString(),
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

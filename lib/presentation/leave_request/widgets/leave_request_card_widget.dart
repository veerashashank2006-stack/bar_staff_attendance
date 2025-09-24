import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaveRequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onResubmit;
  final VoidCallback? onViewDetails;

  const LeaveRequestCardWidget({
    super.key,
    required this.request,
    this.onTap,
    this.onCancel,
    this.onResubmit,
    this.onViewDetails,
  });

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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateRange() {
    final startDate = _formatDate(request['startDate'] as String);
    final endDate = _formatDate(request['endDate'] as String);
    return '$startDate - $endDate';
  }

  String _getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showContextMenu(BuildContext context) {
    final status = request['status'] as String;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'visibility',
                  color: AppTheme.primary,
                  size: 24,
                ),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  onViewDetails?.call();
                },
              ),
              if (status.toLowerCase() == 'pending' && onCancel != null)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'cancel',
                    color: AppTheme.error,
                    size: 24,
                  ),
                  title: const Text('Cancel Request'),
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    onCancel?.call();
                  },
                ),
              if (status.toLowerCase() == 'rejected' && onResubmit != null)
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  title: const Text('Resubmit Request'),
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    onResubmit?.call();
                  },
                ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = request['status'] as String;
    final statusColor = _getStatusColor(status);
    final days = request['days'] as int? ?? 1;
    final reason = request['reason'] as String? ?? '';
    final submittedAt = request['submittedAt'] as String? ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(request['id'] ?? DateTime.now().millisecondsSinceEpoch),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.lightImpact();
                onViewDetails?.call();
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              icon: Icons.visibility,
              label: 'View',
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            if (status.toLowerCase() == 'pending' && onCancel != null)
              SlidableAction(
                onPressed: (context) {
                  HapticFeedback.lightImpact();
                  onCancel?.call();
                },
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.onPrimary,
                icon: Icons.cancel,
                label: 'Cancel',
                borderRadius: status.toLowerCase() == 'pending'
                    ? const BorderRadius.horizontal(right: Radius.circular(12))
                    : BorderRadius.zero,
              ),
            if (status.toLowerCase() == 'rejected' && onResubmit != null)
              SlidableAction(
                onPressed: (context) {
                  HapticFeedback.lightImpact();
                  onResubmit?.call();
                },
                backgroundColor: AppTheme.warning,
                foregroundColor: AppTheme.onPrimary,
                icon: Icons.refresh,
                label: 'Resubmit',
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(12)),
              ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showContextMenu(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconWidget(
                                iconName:
                                    _getStatusIcon(status).codePoint.toString(),
                                color: statusColor,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Duration
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$days day${days == 1 ? '' : 's'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Date Range
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'date_range',
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatDateRange(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.5.h),

                    // Reason Preview
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomIconWidget(
                          iconName: 'edit_note',
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            reason.length > 80
                                ? '${reason.substring(0, 80)}...'
                                : reason,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Footer
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Submitted ${_getTimeAgo(submittedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        CustomIconWidget(
                          iconName: 'arrow_forward_ios',
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

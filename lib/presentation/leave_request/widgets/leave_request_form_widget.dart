import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaveRequestFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const LeaveRequestFormWidget({
    super.key,
    required this.onSubmit,
  });

  @override
  State<LeaveRequestFormWidget> createState() => _LeaveRequestFormWidgetState();
}

class _LeaveRequestFormWidgetState extends State<LeaveRequestFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  final int _maxReasonLength = 500;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: AppTheme.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before the new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      _showSnackBar('Please select start date first', isError: true);
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: AppTheme.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      HapticFeedback.lightImpact();
    }
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
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select both start and end dates', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate number of days
      final int days = _endDate!.difference(_startDate!).inDays + 1;

      final requestData = {
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'reason': _reasonController.text.trim(),
        'days': days,
        'status': 'Pending',
        'submittedAt': DateTime.now().toIso8601String(),
      };

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      widget.onSubmit(requestData);

      // Reset form
      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });

      _showSnackBar('Leave request submitted successfully!');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showSnackBar('Failed to submit request. Please try again.',
          isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  int get _remainingCharacters =>
      _maxReasonLength - _reasonController.text.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Submit New Leave Request',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Fill in the details below to request time off',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 3.h),

            // Start Date Card
            Container(
              width: double.infinity,
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
                  onTap: _selectStartDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'calendar_today',
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
                                'Start Date',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _startDate != null
                                    ? _formatDate(_startDate!)
                                    : 'Select start date',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: _startDate != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                  fontWeight: _startDate != null
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'arrow_forward_ios',
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // End Date Card
            Container(
              width: double.infinity,
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
                  onTap: _selectEndDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'event',
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
                                'End Date',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'Select end date',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: _endDate != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                  fontWeight: _endDate != null
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'arrow_forward_ios',
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Duration Display
            if (_startDate != null && _endDate != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Duration: ${_endDate!.difference(_startDate!).inDays + 1} day(s)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_startDate != null && _endDate != null) SizedBox(height: 2.h),

            // Reason Field
            Container(
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
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'edit_note',
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Reason for Leave',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      maxLength: _maxReasonLength,
                      decoration: InputDecoration(
                        hintText:
                            'Please provide a reason for your leave request...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason for your leave';
                        }
                        if (value.trim().length < 10) {
                          return 'Reason must be at least 10 characters';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minimum 10 characters required',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '$_remainingCharacters characters left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _remainingCharacters < 50
                                ? AppTheme.warning
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onPrimary,
                  elevation: 4,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: colorScheme.outline,
                  disabledForegroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Submitting...',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'send',
                            color: AppTheme.onPrimary,
                            size: 18,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Submit Request',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

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
  String? _selectedLeaveType;
  bool _isSubmitting = false;

  final int _maxReasonLength = 500;

  final List<String> _leaveTypes = ['Sick', 'Casual', 'Paid', 'Unpaid'];

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
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
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
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select both start and end dates', isError: true);
      return;
    }
    if (_selectedLeaveType == null) {
      _showSnackBar('Please select leave type', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final int days = _endDate!.difference(_startDate!).inDays + 1;

      final requestData = {
        'leaveType': _selectedLeaveType,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'days': days,
        'reason': _reasonController.text.trim(),
      };

      widget.onSubmit(requestData);

      setState(() {
        _startDate = null;
        _endDate = null;
        _selectedLeaveType = null;
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
    return '${date.month}/${date.day}/${date.year}';
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
            Text('Submit New Leave Request',
                style: theme.textTheme.headlineSmall),
            SizedBox(height: 2.h),

            // Leave Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLeaveType,
              items: _leaveTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Leave Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => setState(() => _selectedLeaveType = val),
              validator: (val) =>
                  val == null ? "Please select a leave type" : null,
            ),
            SizedBox(height: 2.h),

            // Start & End Date
            _buildDateCard(
                title: 'Start Date',
                selectedDate: _startDate,
                onTap: _selectStartDate),
            SizedBox(height: 2.h),
            _buildDateCard(
                title: 'End Date',
                selectedDate: _endDate,
                onTap: _selectEndDate),
            SizedBox(height: 2.h),

            if (_startDate != null && _endDate != null)
              Text("Duration: ${_endDate!.difference(_startDate!).inDays + 1} days",
                  style: theme.textTheme.bodyMedium),

            SizedBox(height: 2.h),

            // Reason
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: _maxReasonLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason';
                }
                if (value.trim().length < 10) {
                  return 'Reason must be at least 10 characters';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Reason for Leave',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 4.h),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          selectedDate != null ? _formatDate(selectedDate) : 'Select $title',
        ),
      ),
    );
  }
}

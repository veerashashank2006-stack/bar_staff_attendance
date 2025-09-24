import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/leave_request.dart';

class LeaveService {
  static final SupabaseClient _client = SupabaseService.instance.client;

  /// Get leave requests for current user
  static Future<List<LeaveRequest>> getMyLeaveRequests({
    LeaveStatus? status,
    int? limit,
  }) async {
    try {
      var query = _client.from('leave_requests').select();

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit ?? 50);

      return response
          .map<LeaveRequest>((json) => LeaveRequest.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get leave requests: $error');
    }
  }

  /// Get all leave requests (for managers)
  static Future<List<LeaveRequest>> getAllLeaveRequests({
    String? userId,
    LeaveStatus? status,
    int? limit,
  }) async {
    try {
      var query = _client.from('leave_requests').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit ?? 100);

      return response
          .map<LeaveRequest>((json) => LeaveRequest.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get leave requests: $error');
    }
  }

  /// Create a new leave request
  static Future<LeaveRequest> createLeaveRequest({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      // Calculate total days
      final totalDays = endDate.difference(startDate).inDays + 1;

      // Check for overlapping leave requests
      final overlapping = await _client
          .from('leave_requests')
          .select()
          .or('start_date.lte.${endDate.toIso8601String().split('T')[0]},end_date.gte.${startDate.toIso8601String().split('T')[0]}')
          .eq('status', 'approved')
          .maybeSingle();

      if (overlapping != null) {
        throw Exception('You have an overlapping approved leave request');
      }

      final response = await _client
          .from('leave_requests')
          .insert({
            'leave_type': leaveType.toString().split('.').last,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate.toIso8601String().split('T')[0],
            'total_days': totalDays,
            'reason': reason,
            'status': 'pending',
          })
          .select()
          .single();

      return LeaveRequest.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create leave request: $error');
    }
  }

  /// Update leave request status (for managers)
  static Future<LeaveRequest> updateLeaveRequestStatus({
    required String requestId,
    required LeaveStatus status,
    String? managerNotes,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'approved_at': status == LeaveStatus.approved
            ? DateTime.now().toIso8601String()
            : null,
        'manager_notes': managerNotes,
      };

      final response = await _client
          .from('leave_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      return LeaveRequest.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update leave request: $error');
    }
  }

  /// Update leave request (before approval)
  static Future<LeaveRequest> updateLeaveRequest({
    required String requestId,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
  }) async {
    try {
      // Check if request is still pending
      final existing = await _client
          .from('leave_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (existing['status'] != 'pending') {
        throw Exception('Cannot update non-pending leave request');
      }

      final updateData = <String, dynamic>{};

      if (leaveType != null) {
        updateData['leave_type'] = leaveType.toString().split('.').last;
      }

      if (startDate != null) {
        updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        updateData['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      if (reason != null) {
        updateData['reason'] = reason;
      }

      // Recalculate total days if dates changed
      if (startDate != null || endDate != null) {
        final start = startDate ?? DateTime.parse(existing['start_date']);
        final end = endDate ?? DateTime.parse(existing['end_date']);
        updateData['total_days'] = end.difference(start).inDays + 1;
      }

      final response = await _client
          .from('leave_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      return LeaveRequest.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update leave request: $error');
    }
  }

  /// Delete leave request (only if pending)
  static Future<void> deleteLeaveRequest(String requestId) async {
    try {
      // Check if request is still pending
      final existing = await _client
          .from('leave_requests')
          .select()
          .eq('id', requestId)
          .single();

      if (existing['status'] != 'pending') {
        throw Exception('Cannot delete non-pending leave request');
      }

      await _client.from('leave_requests').delete().eq('id', requestId);
    } catch (error) {
      throw Exception('Failed to delete leave request: $error');
    }
  }

  /// Get leave balance summary
  static Future<Map<String, dynamic>> getLeaveBalance({
    String? userId,
    int? year,
  }) async {
    try {
      final currentYear = year ?? DateTime.now().year;

      var query = _client
          .from('leave_requests')
          .select()
          .eq('status', 'approved')
          .gte('start_date', '$currentYear-01-01')
          .lte('end_date', '$currentYear-12-31');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final approvedLeaves = await query;

      final totalUsed = approvedLeaves.fold<int>(
          0, (sum, leave) => sum + (leave['total_days'] as int));

      final casualUsed = approvedLeaves
          .where((leave) => leave['leave_type'] == 'casual')
          .fold<int>(0, (sum, leave) => sum + (leave['total_days'] as int));

      final sickUsed = approvedLeaves
          .where((leave) => leave['leave_type'] == 'sick')
          .fold<int>(0, (sum, leave) => sum + (leave['total_days'] as int));

      final vacationUsed = approvedLeaves
          .where((leave) => leave['leave_type'] == 'vacation')
          .fold<int>(0, (sum, leave) => sum + (leave['total_days'] as int));

      // Standard leave allowances (can be customized per company)
      const int totalAllowance = 30;
      const int casualAllowance = 12;
      const int sickAllowance = 12;
      const int vacationAllowance = 21;

      return {
        'total_used': totalUsed,
        'total_remaining': totalAllowance - totalUsed,
        'casual_used': casualUsed,
        'casual_remaining': casualAllowance - casualUsed,
        'sick_used': sickUsed,
        'sick_remaining': sickAllowance - sickUsed,
        'vacation_used': vacationUsed,
        'vacation_remaining': vacationAllowance - vacationUsed,
        'year': currentYear,
      };
    } catch (error) {
      throw Exception('Failed to get leave balance: $error');
    }
  }

  /// Get pending leave requests count (for managers)
  static Future<int> getPendingLeaveRequestsCount() async {
    try {
      final response = await _client
          .from('leave_requests')
          .select()
          .eq('status', 'pending')
          .count();

      return response.count ?? 0;
    } catch (error) {
      throw Exception('Failed to get pending requests count: $error');
    }
  }
}

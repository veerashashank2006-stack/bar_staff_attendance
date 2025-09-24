import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static final SupabaseClient _client = SupabaseService.instance.client;

  /// Get attendance records for current user
  static Future<List<AttendanceRecord>> getMyAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _client.from('attendance_records').select();

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response =
          await query.order('date', ascending: false).limit(limit ?? 100);

      return response
          .map<AttendanceRecord>((json) => AttendanceRecord.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get attendance records: $error');
    }
  }

  /// Get all attendance records (for managers)
  static Future<List<AttendanceRecord>> getAllAttendanceRecords({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _client.from('attendance_records').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit ?? 100);

      return response
          .map<AttendanceRecord>((json) => AttendanceRecord.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get attendance records: $error');
    }
  }

  /// Check in
  static Future<AttendanceRecord> checkIn({
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already checked in today
      final existing = await _client
          .from('attendance_records')
          .select()
          .eq('date', today.toIso8601String().split('T')[0])
          .maybeSingle();

      if (existing != null) {
        throw Exception('Already checked in today');
      }

      final response = await _client
          .from('attendance_records')
          .insert({
            'date': today.toIso8601String().split('T')[0],
            'check_in_time': now.toIso8601String(),
            'status': _getStatusFromTime(now),
            'location_lat': latitude,
            'location_lng': longitude,
            'notes': notes,
          })
          .select()
          .single();

      return AttendanceRecord.fromJson(response);
    } catch (error) {
      throw Exception('Check-in failed: $error');
    }
  }

  /// Check out
  static Future<AttendanceRecord> checkOut({String? notes}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Find today's attendance record
      final existing = await _client
          .from('attendance_records')
          .select()
          .eq('date', today.toIso8601String().split('T')[0])
          .maybeSingle();

      if (existing == null) {
        throw Exception('No check-in record found for today');
      }

      if (existing['check_out_time'] != null) {
        throw Exception('Already checked out today');
      }

      final response = await _client
          .from('attendance_records')
          .update({
            'check_out_time': now.toIso8601String(),
            'notes': notes ?? existing['notes'],
          })
          .eq('id', existing['id'])
          .select()
          .single();

      return AttendanceRecord.fromJson(response);
    } catch (error) {
      throw Exception('Check-out failed: $error');
    }
  }

  /// Get today's attendance
  static Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      final today = DateTime.now();
      final dateString = DateTime(today.year, today.month, today.day)
          .toIso8601String()
          .split('T')[0];

      final response = await _client
          .from('attendance_records')
          .select()
          .eq('date', dateString)
          .maybeSingle();

      if (response != null) {
        return AttendanceRecord.fromJson(response);
      }
      return null;
    } catch (error) {
      throw Exception('Failed to get today\'s attendance: $error');
    }
  }

  /// Get attendance summary for a date range
  static Future<Map<String, dynamic>> getAttendanceSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      var query = _client
          .from('attendance_records')
          .select()
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final records = await query;

      final totalDays = records.length;
      final presentDays = records
          .where((r) => r['status'] == 'present' || r['status'] == 'late')
          .length;
      final lateDays = records.where((r) => r['status'] == 'late').length;
      final absentDays = records.where((r) => r['status'] == 'absent').length;

      return {
        'total_days': totalDays,
        'present_days': presentDays,
        'late_days': lateDays,
        'absent_days': absentDays,
        'attendance_rate': totalDays > 0
            ? double.parse(((presentDays / totalDays) * 100).toStringAsFixed(2))
            : 0.0,
      };
    } catch (error) {
      throw Exception('Failed to get attendance summary: $error');
    }
  }

  /// Update attendance record (for managers)
  static Future<AttendanceRecord> updateAttendanceRecord({
    required String recordId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceStatus? status,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (checkInTime != null) {
        updateData['check_in_time'] = checkInTime.toIso8601String();
      }

      if (checkOutTime != null) {
        updateData['check_out_time'] = checkOutTime.toIso8601String();
      }

      if (status != null) {
        updateData['status'] = status
            .toString()
            .split('.')
            .last
            .replaceAll(RegExp(r'([A-Z])'), '_\$1')
            .toLowerCase()
            .replaceFirst('_', '');
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      final response = await _client
          .from('attendance_records')
          .update(updateData)
          .eq('id', recordId)
          .select()
          .single();

      return AttendanceRecord.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update attendance record: $error');
    }
  }

  /// Delete attendance record (for managers)
  static Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await _client.from('attendance_records').delete().eq('id', recordId);
    } catch (error) {
      throw Exception('Failed to delete attendance record: $error');
    }
  }

  /// Helper method to determine status from check-in time
  static String _getStatusFromTime(DateTime checkInTime) {
    final expectedCheckInTime = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      9, // 9 AM
      0,
    );

    if (checkInTime
        .isAfter(expectedCheckInTime.add(const Duration(minutes: 15)))) {
      return 'late';
    }
    return 'present';
  }

  // Enhanced QR-based attendance methods
  static Future<AttendanceRecord> checkInWithQR({
    required String qrCode,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Validate QR code format and date
      final response = await _client.rpc('validate_qr_attendance_code',
          params: {'qr_code_input': qrCode});

      if (response != true) {
        throw Exception('Invalid or expired QR code');
      }

      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Check if user already checked in today
      final existingAttendance = await _client
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .limit(1)
          .maybeSingle();

      if (existingAttendance != null) {
        throw Exception('Already checked in today');
      }

      // Determine status based on time
      final now = DateTime.now();
      final workStartTime =
          DateTime(now.year, now.month, now.day, 9, 0); // 9 AM
      final lateThreshold =
          workStartTime.add(const Duration(minutes: 15)); // 9:15 AM

      String status = 'present';
      if (now.isAfter(lateThreshold)) {
        status = 'late';
      }

      // Create attendance record
      final attendanceData = {
        'user_id': userId,
        'date': today,
        'check_in_time': now.toIso8601String(),
        'status': status,
        'location_lat': latitude,
        'location_lng': longitude,
        'qr_code': qrCode,
        'notes': notes ?? 'QR Check-in: $qrCode',
      };

      final response2 = await _client
          .from('attendance_records')
          .insert(attendanceData)
          .select()
          .single();

      return AttendanceRecord.fromJson(response2);
    } catch (e) {
      throw Exception('Failed to check in with QR: ${e.toString()}');
    }
  }

  static Future<AttendanceRecord> checkOutWithQR({
    required String qrCode,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Validate QR code format and date
      final response = await _client.rpc('validate_qr_attendance_code',
          params: {'qr_code_input': qrCode});

      if (response != true) {
        throw Exception('Invalid or expired QR code');
      }

      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get today's attendance record
      final existingAttendance = await _client
          .from('attendance_records')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .limit(1)
          .maybeSingle();

      if (existingAttendance == null) {
        throw Exception('No check-in record found for today');
      }

      if (existingAttendance['check_out_time'] != null) {
        throw Exception('Already checked out today');
      }

      final now = DateTime.now();
      final updatedNotes = notes ?? 'QR Check-out: $qrCode';

      // Update attendance record with check-out time
      final response2 = await _client
          .from('attendance_records')
          .update({
            'check_out_time': now.toIso8601String(),
            'notes': existingAttendance['notes'] + ' | ' + updatedNotes,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', existingAttendance['id'])
          .select()
          .single();

      return AttendanceRecord.fromJson(response2);
    } catch (e) {
      throw Exception('Failed to check out with QR: ${e.toString()}');
    }
  }

  // Generate daily QR code
  static Future<String> getDailyQRCode() async {
    try {
      final response = await _client.rpc('get_daily_qr_code');
      return response as String;
    } catch (e) {
      throw Exception('Failed to get daily QR code: ${e.toString()}');
    }
  }

  // Validate QR code format
  static Future<bool> validateQRCode(String qrCode) async {
    try {
      final response = await _client.rpc('validate_qr_attendance_code',
          params: {'qr_code_input': qrCode});
      return response == true;
    } catch (e) {
      return false;
    }
  }
}
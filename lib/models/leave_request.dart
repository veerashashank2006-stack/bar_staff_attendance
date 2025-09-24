enum LeaveStatus { pending, approved, rejected }

enum LeaveType { sick, casual, vacation, maternity, paternity, emergency }

class LeaveRequest {
  final String id;
  final String userId;
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? managerNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.managerNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      leaveType: LeaveType.values.firstWhere(
        (e) => e.toString().split('.').last == json['leave_type'],
        orElse: () => LeaveType.casual,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalDays: json['total_days'] as int,
      reason: json['reason'] as String,
      status: LeaveStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      managerNotes: json['manager_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'leave_type': leaveType.toString().split('.').last,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'reason': reason,
      'status': status.toString().split('.').last,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'manager_notes': managerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LeaveRequest copyWith({
    String? id,
    String? userId,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    String? reason,
    LeaveStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? managerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      managerNotes: managerNotes ?? this.managerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayLeaveType {
    switch (leaveType) {
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.vacation:
        return 'Vacation';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.emergency:
        return 'Emergency Leave';
    }
  }

  String get displayStatus {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;
  bool get isRejected => status == LeaveStatus.rejected;
}

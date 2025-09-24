
enum UserRole { admin, manager, employee }

class UserProfile {
  final String id;
  final String employeeId;
  final String email;
  final String fullName;
  final String? phone;
  final String? department;
  final String? position;
  final UserRole role;
  final bool isActive;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.employeeId,
    required this.email,
    required this.fullName,
    this.phone,
    this.department,
    this.position,
    required this.role,
    required this.isActive,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.employee,
      ),
      isActive: json['is_active'] as bool? ?? true,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'department': department,
      'position': position,
      'role': role.toString().split('.').last,
      'is_active': isActive,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? employeeId,
    String? email,
    String? fullName,
    String? phone,
    String? department,
    String? position,
    UserRole? role,
    bool? isActive,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      position: position ?? this.position,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;

  String get displayRole {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseService.instance.client;

  // Current user
  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => _client.auth.currentUser?.id;

  // Auth state stream
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Sign up a new user
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? employeeId,
    UserRole role = UserRole.employee,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'employee_id':
              employeeId ?? 'EMP${DateTime.now().millisecondsSinceEpoch}',
          'role': role.toString().split('.').last,
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  /// Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  /// Update password
  static Future<UserResponse> updatePassword(
      {required String newPassword}) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  /// Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Update user profile
  static Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Check if user has specific role
  static Future<bool> hasRole(UserRole role) async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.role == role;
    } catch (error) {
      return false;
    }
  }

  /// Check if user is admin
  static Future<bool> get isAdmin async {
    return await hasRole(UserRole.admin);
  }

  /// Check if user is manager or admin
  static Future<bool> get isManager async {
    final profile = await getCurrentUserProfile();
    return profile?.isManager ?? false;
  }

  /// Refresh session
  static Future<void> refreshSession() async {
    try {
      await _client.auth.refreshSession();
    } catch (error) {
      throw Exception('Session refresh failed: $error');
    }
  }
}

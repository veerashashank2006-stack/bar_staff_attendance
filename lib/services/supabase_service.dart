import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a single Supabase client for the entire app.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Your Supabase project credentials from environment variables
  /// (anon key is safe to use on the client side).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Initialize Supabase before runApp() in main.dart
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url:
            supabaseUrl.isNotEmpty
                ? supabaseUrl
                : 'https://xiighmqicyukhsncwwpw.supabase.co',
        anonKey:
            supabaseAnonKey.isNotEmpty
                ? supabaseAnonKey
                : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpaWdobXFpY3l1a2hzbmN3d3B3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2Mzk0ODksImV4cCI6MjA3NDIxNTQ4OX0.A854oHZ6ij3ta0GXXc5zZU8vPycPY5Ivg_sa_At-Qx8',
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization error: $e');
      rethrow;
    }
  }

  /// Access the Supabase client anywhere in the app:
  /// `SupabaseService.instance.client`
  SupabaseClient get client => Supabase.instance.client;

  /// Quick access to auth
  GoTrueClient get auth => client.auth;

  /// Quick access to database
  PostgrestQueryBuilder from(String table) => client.from(table);

  /// Quick access to realtime
  RealtimeClient get realtime => client.realtime;

  /// Quick access to storage
  SupabaseStorageClient get storage => client.storage;

  /// Check if user is currently signed in
  bool get isSignedIn => auth.currentUser != null;

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.id;
}
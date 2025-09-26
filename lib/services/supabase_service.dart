import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides a single Supabase client for the entire app.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Your Supabase project credentials
  /// (anon key is safe to use on the client side).
  static const String supabaseUrl = 'https://xiighmqicyukhsncwwpw.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpaWdobXFpY3l1a2hzbmN3d3B3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2Mzk0ODksImV4cCI6MjA3NDIxNTQ4OX0.A854oHZ6ij3ta0GXXc5zZU8vPycPY5Ivg_sa_At-Qx8';

  /// Initialize Supabase before runApp() in main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Access the Supabase client anywhere in the app:
  /// `SupabaseService.instance.client`
  SupabaseClient get client => Supabase.instance.client;
}

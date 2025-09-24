import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/notification.dart';

class NotificationService {
  static final SupabaseClient _client = SupabaseService.instance.client;

  /// Get notifications for current user
  static Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    int? limit,
  }) async {
    try {
      var query = _client.from('notifications').select();

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit ?? 50);

      return response
          .map<NotificationModel>((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get notifications: $error');
    }
  }

  /// Get unread notifications count
  static Future<int> getUnreadCount() async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('is_read', false)
          .count();

      return response.count ?? 0;
    } catch (error) {
      throw Exception('Failed to get unread count: $error');
    }
  }

  /// Mark notification as read
  static Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('is_read', false);
    } catch (error) {
      throw Exception('Failed to mark all notifications as read: $error');
    }
  }

  /// Create notification (for system/managers)
  static Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': title,
            'message': message,
            'type': type,
            'data': data,
          })
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create notification: $error');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (error) {
      throw Exception('Failed to delete notification: $error');
    }
  }

  /// Delete all read notifications
  static Future<void> deleteAllRead() async {
    try {
      await _client.from('notifications').delete().eq('is_read', true);
    } catch (error) {
      throw Exception('Failed to delete read notifications: $error');
    }
  }

  /// Subscribe to real-time notifications
  static RealtimeChannel subscribeToNotifications({
    required Function(NotificationModel) onNotificationReceived,
    required Function(String) onNotificationUpdated,
  }) {
    return _client
        .channel('notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final notification =
                NotificationModel.fromJson(payload.newRecord);
            onNotificationReceived(notification);
                    },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            onNotificationUpdated(payload.newRecord['id'] as String);
                    },
        )
        .subscribe();
  }

  /// Send notification to multiple users
  static Future<List<NotificationModel>> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifications = userIds
          .map((userId) => {
                'user_id': userId,
                'title': title,
                'message': message,
                'type': type,
                'data': data,
              })
          .toList();

      final response =
          await _client.from('notifications').insert(notifications).select();

      return response
          .map<NotificationModel>((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to send bulk notifications: $error');
    }
  }
}

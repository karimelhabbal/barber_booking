import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<NotificationModel>> loadNotifications({
    required String recipientId,
  });

  Future<void> markAsRead({required String notificationId});

  Future<void> markAllAsRead({required String recipientId});

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  });

  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this._client});

  final SupabaseClient _client;

  @override
  Future<List<NotificationModel>> loadNotifications({
    required String recipientId,
  }) async {
    final rows = await _client
        .from('notifications')
        .select(
          'id, recipient_id, type, title, body, booking_id, created_at, is_read',
        )
        .eq('recipient_id', recipientId)
        .order('created_at', ascending: false);

    return rows.map(NotificationModel.fromJson).toList(growable: false);
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    final updated = await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw StateError('Notification was not found or cannot be updated.');
    }
  }

  @override
  Future<void> markAllAsRead({required String recipientId}) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', recipientId)
        .eq('is_read', false)
        .select('id');
  }

  @override
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedToken = token.trim();

    if (trimmedUserId.isEmpty || trimmedToken.isEmpty) {
      return;
    }

    if (_client.auth.currentUser?.id != trimmedUserId) {
      throw StateError('Cannot register a device token for another user.');
    }

    await _client.rpc(
      'register_device_token',
      params: {'p_token': trimmedToken, 'p_platform': platform},
    );
  }

  @override
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedToken = token.trim();

    if (trimmedUserId.isEmpty || trimmedToken.isEmpty) {
      return;
    }

    await _client
        .from('device_tokens')
        .delete()
        .eq('user_id', trimmedUserId)
        .eq('token', trimmedToken);
  }
}

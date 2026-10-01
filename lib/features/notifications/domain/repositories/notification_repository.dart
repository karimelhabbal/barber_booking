import '../entities/notification.dart';

/// Contract of the shared notifications feature.
///
/// One repository serves every role; notifications are scoped by the
/// [recipientId] of the authenticated user. Only the interface exists for now:
/// a Firestore backed implementation replaces the in-memory one later without
/// touching cubits or UI.
abstract interface class NotificationRepository {
  Future<List<AppNotification>> loadNotifications({
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

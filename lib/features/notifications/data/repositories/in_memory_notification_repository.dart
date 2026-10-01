import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Minimal in-memory implementation that keeps the notifications UI usable
/// before a real data source exists.
///
/// It starts empty on purpose and never fabricates data, so nothing shown can
/// be mistaken for a real notification. Reading state is shared by all
/// notifications Cubits created during the session.
class InMemoryNotificationRepository implements NotificationRepository {
  InMemoryNotificationRepository();

  final List<AppNotification> _notifications = [];

  @override
  Future<List<AppNotification>> loadNotifications({
    required String recipientId,
  }) async {
    return _notifications
        .where((notification) => notification.recipientId == recipientId)
        .toList();
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );

    if (index == -1) {
      return;
    }

    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead({required String recipientId}) async {
    for (var index = 0; index < _notifications.length; index++) {
      final notification = _notifications[index];

      if (notification.recipientId != recipientId || notification.isRead) {
        continue;
      }

      _notifications[index] = notification.copyWith(isRead: true);
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    // Device tokens are only meaningful with a real backend.
  }

  @override
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) async {
    // Device tokens are only meaningful with a real backend.
  }
}

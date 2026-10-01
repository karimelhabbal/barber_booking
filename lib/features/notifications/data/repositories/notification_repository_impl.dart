import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this._remoteDataSource});

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<AppNotification>> loadNotifications({
    required String recipientId,
  }) {
    return _remoteDataSource.loadNotifications(recipientId: recipientId);
  }

  @override
  Future<void> markAsRead({required String notificationId}) {
    return _remoteDataSource.markAsRead(notificationId: notificationId);
  }

  @override
  Future<void> markAllAsRead({required String recipientId}) {
    return _remoteDataSource.markAllAsRead(recipientId: recipientId);
  }

  @override
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _remoteDataSource.registerDeviceToken(
      userId: userId,
      token: token,
      platform: platform,
    );
  }

  @override
  Future<void> unregisterDeviceToken({
    required String userId,
    required String token,
  }) {
    return _remoteDataSource.unregisterDeviceToken(
      userId: userId,
      token: token,
    );
  }
}

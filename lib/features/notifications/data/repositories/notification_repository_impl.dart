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
}

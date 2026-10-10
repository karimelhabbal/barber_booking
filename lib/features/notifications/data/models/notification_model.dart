import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.recipientId,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    super.bookingId,
    super.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'];
    if (createdAtValue is! String) {
      throw StateError('Notification ${json['id']} has an invalid created_at.');
    }

    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw StateError('Notification ${json['id']} has an invalid created_at.');
    }

    final bookingIdValue = json['booking_id'];
    if (bookingIdValue != null && bookingIdValue is! String) {
      throw StateError('Notification ${json['id']} has an invalid booking_id.');
    }

    final isReadValue = json['is_read'];
    if (isReadValue is! bool) {
      throw StateError('Notification ${json['id']} has an invalid is_read.');
    }

    return NotificationModel(
      id: _requiredString(json, 'id'),
      recipientId: _requiredString(json, 'recipient_id'),
      type: _notificationTypeFromDatabase(json['type']),
      title: _requiredString(json, 'title'),
      body: _requiredString(json, 'body'),
      bookingId: bookingIdValue,
      createdAt: createdAt,
      isRead: isReadValue,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw StateError('Notification ${json['id']} has an invalid $key.');
    }
    return value;
  }

  static NotificationType _notificationTypeFromDatabase(Object? value) {
    switch (value) {
      case 'bookingCreated':
        return NotificationType.bookingCreated;
      case 'bookingConfirmed':
        return NotificationType.bookingConfirmed;
      case 'bookingRejected':
        return NotificationType.bookingRejected;
      case 'bookingCancelled':
        return NotificationType.bookingCancelled;
      case 'bookingCompleted':
        return NotificationType.bookingCompleted;
      case 'bookingNoShow':
        return NotificationType.bookingNoShow;
      case 'appointmentReminder':
        return NotificationType.appointmentReminder;
      case 'scheduleChanged':
        return NotificationType.scheduleChanged;
      case 'paymentSuccess':
        return NotificationType.paymentSuccess;
      case 'general':
        return NotificationType.general;
      default:
        throw StateError('Unknown notification type: $value');
    }
  }
}

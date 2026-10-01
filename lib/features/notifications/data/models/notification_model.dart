import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();

    if (data == null) {
      throw StateError(
        'Notification document ${snapshot.id} contains no data.',
      );
    }

    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw StateError(
        'Notification document ${snapshot.id} has an invalid createdAt.',
      );
    }

    return NotificationModel(
      id: snapshot.id,
      recipientId: data['recipientId'] as String,
      type: _notificationTypeFromFirestore(data['type']),
      title: data['title'] as String,
      body: data['body'] as String,
      bookingId: data['bookingId'] as String?,
      createdAt: createdAt.toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'type': _notificationTypeToFirestore(type),
      'title': title,
      'body': body,
      'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  static NotificationType _notificationTypeFromFirestore(Object? value) {
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
      case 'general':
        return NotificationType.general;
      default:
        throw StateError('Unknown notification type: $value');
    }
  }

  static String _notificationTypeToFirestore(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return 'bookingCreated';
      case NotificationType.bookingConfirmed:
        return 'bookingConfirmed';
      case NotificationType.bookingRejected:
        return 'bookingRejected';
      case NotificationType.bookingCancelled:
        return 'bookingCancelled';
      case NotificationType.bookingCompleted:
        return 'bookingCompleted';
      case NotificationType.bookingNoShow:
        return 'bookingNoShow';
      case NotificationType.appointmentReminder:
        return 'appointmentReminder';
      case NotificationType.scheduleChanged:
        return 'scheduleChanged';
      case NotificationType.general:
        return 'general';
    }
  }
}

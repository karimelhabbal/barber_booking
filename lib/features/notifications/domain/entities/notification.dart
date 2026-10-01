import 'package:equatable/equatable.dart';

/// Kind of a notification.
///
/// Kept free of backend concerns: a future data source maps its own values
/// onto these cases (and back) without touching the domain.
enum NotificationType {
  bookingCreated,
  bookingConfirmed,
  bookingRejected,
  bookingCancelled,
  bookingCompleted,
  bookingNoShow,
  appointmentReminder,
  scheduleChanged,
  general,
}

/// A single notification addressed to one recipient user.
///
/// Named [AppNotification] so it never clashes with Flutter's own
/// `Notification` widget class.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.bookingId,
    this.isRead = false,
  });

  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;

  /// Related booking, when the notification is about one. Kept for future
  /// deep-linking; no navigation is performed yet.
  final String? bookingId;

  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      body: body,
      bookingId: bookingId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
    id,
    recipientId,
    type,
    title,
    body,
    bookingId,
    createdAt,
    isRead,
  ];
}

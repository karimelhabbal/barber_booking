import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notifications_state.dart';

/// Shared notifications Cubit used by every role.
///
/// It is role agnostic: the caller supplies the authenticated user id as the
/// recipient, so there is no separate customer/owner/barber implementation.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({required this._repository})
    : super(const NotificationsInitial());

  final NotificationRepository _repository;

  String _recipientId = '';

  Future<void> loadNotifications({required String recipientId}) async {
    final trimmedRecipientId = recipientId.trim();

    if (trimmedRecipientId.isEmpty) {
      emit(const NotificationsError('Recipient ID cannot be empty.'));
      return;
    }

    _recipientId = trimmedRecipientId;

    emit(const NotificationsLoading());

    try {
      final notifications = await _repository.loadNotifications(
        recipientId: trimmedRecipientId,
      );

      emit(NotificationsLoaded(notifications: _newestFirst(notifications)));
    } on Object catch (error) {
      emit(NotificationsError(_mapError(error)));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final trimmedNotificationId = notificationId.trim();
    final currentState = state;

    final shouldUpdate =
        currentState is NotificationsLoaded &&
        trimmedNotificationId.isNotEmpty &&
        currentState.notifications.any(
          (notification) =>
              notification.id == trimmedNotificationId && !notification.isRead,
        );

    if (!shouldUpdate) {
      return;
    }

    try {
      await _repository.markAsRead(notificationId: trimmedNotificationId);

      if (isClosed) {
        return;
      }

      final latestState = state;

      if (latestState is! NotificationsLoaded) {
        return;
      }

      // Updates the current state instead of reloading the whole list.
      emit(
        NotificationsLoaded(
          notifications: [
            for (final notification in latestState.notifications)
              notification.id == trimmedNotificationId
                  ? notification.copyWith(isRead: true)
                  : notification,
          ],
        ),
      );
    } on Object catch (error) {
      emit(NotificationsError(_mapError(error)));
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;

    final shouldUpdate =
        _recipientId.isNotEmpty &&
        currentState is NotificationsLoaded &&
        currentState.hasUnread;

    if (!shouldUpdate) {
      return;
    }

    try {
      await _repository.markAllAsRead(recipientId: _recipientId);

      if (isClosed) {
        return;
      }

      final latestState = state;

      if (latestState is! NotificationsLoaded) {
        return;
      }

      emit(
        NotificationsLoaded(
          notifications: [
            for (final notification in latestState.notifications)
              notification.copyWith(isRead: true),
          ],
        ),
      );
    } on Object catch (error) {
      emit(NotificationsError(_mapError(error)));
    }
  }

  List<AppNotification> _newestFirst(List<AppNotification> notifications) {
    return [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _mapError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }

    if (message.toLowerCase().contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }
}

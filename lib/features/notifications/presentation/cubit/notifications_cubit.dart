import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../services/notification_service.dart';

part 'notifications_state.dart';

/// Shared notifications Cubit used by every role.
///
/// It is role agnostic: the caller supplies the authenticated user id as the
/// recipient, so there is no separate customer/owner/barber implementation.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required this._repository,
    required this._notificationService,
  }) : super(const NotificationsInitial());

  final NotificationRepository _repository;
  final NotificationService _notificationService;

  String _recipientId = '';
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Id of the user the loaded notifications belong to (empty before [start]).
  String get recipientId => _recipientId;

  bool get isStarted => _recipientId.isNotEmpty;

  /// Starts the notification session for the authenticated user.
  ///
  /// Registers this device for push notifications, keeps the list in sync with
  /// foreground pushes, then loads the notifications.
  ///
  /// [role] and [shopId] are part of the notification session contract; the
  /// current backend scopes notifications by recipient id only, so they are
  /// not required to fetch or subscribe.
  Future<void> start({
    required String userId,
    required UserRole role,
    String? shopId,
  }) async {
    final trimmedUserId = userId.trim();

    if (trimmedUserId.isEmpty) {
      return;
    }

    _recipientId = trimmedUserId;

    _foregroundSubscription ??= _notificationService.foregroundMessages.listen(
      (_) => loadNotifications(recipientId: trimmedUserId),
    );

    await _notificationService.registerDevice(userId: trimmedUserId);

    await loadNotifications(recipientId: trimmedUserId);
  }

  /// Stops the notification session before signing out.
  ///
  /// Removes this device's token so the previous account stops receiving
  /// pushes here once another user signs in on the same device.
  Future<void> stop() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;

    await _notificationService.unregisterDevice();

    _recipientId = '';

    if (!isClosed) {
      emit(const NotificationsInitial());
    }
  }

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

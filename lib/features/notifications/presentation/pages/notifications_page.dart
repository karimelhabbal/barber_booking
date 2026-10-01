import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/empty_view.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/features/notifications/domain/entities/notification.dart';
import 'package:barber_booking/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:barber_booking/features/notifications/presentation/widgets/notification_card.dart';
import 'package:barber_booking/features/notifications/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Shared notifications screen for customers, owners and barbers.
///
/// The screen is role agnostic: the caller only supplies the authenticated
/// user id used to scope the notifications, so there is no per-role screen.
/// It uses the single global [NotificationsCubit] so the unread badge, push
/// updates and this list always share one source of truth.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.recipientId});

  /// Id of the user the notifications belong to.
  final String recipientId;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      // The global cubit already loads on start; refreshing here keeps the
      // screen current when it is opened from a notification tap.
      context.read<NotificationsCubit>().loadNotifications(
        recipientId: widget.recipientId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _NotificationsView(recipientId: widget.recipientId);
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView({required this.recipientId});

  final String recipientId;

  Future<void> _refresh(BuildContext context) {
    return context.read<NotificationsCubit>().loadNotifications(
      recipientId: recipientId,
    );
  }

  void _openNotification(BuildContext context, AppNotification notification) {
    context.read<NotificationsCubit>().markAsRead(notification.id);

    final bookingId = notification.bookingId?.trim() ?? '';

    if (bookingId.isEmpty ||
        !NotificationService.bookingNotificationTypes.contains(
          notification.type.name,
        )) {
      return;
    }

    context.push(
      '${NotificationService.bookingDetailsRoute}'
      '?bookingId=${Uri.encodeComponent(bookingId)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final loadedState = state is NotificationsLoaded ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.notifications),
            actions: [
              if (loadedState != null && loadedState.hasUnread)
                IconButton(
                  tooltip: loc.markAllAsRead,
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllAsRead(),
                  icon: const Icon(Icons.mark_email_read_outlined),
                ),
            ],
          ),
          body: SafeArea(child: _content(context, loc, state)),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations loc,
    NotificationsState state,
  ) {
    if (state is NotificationsInitial || state is NotificationsLoading) {
      return const LoadingView();
    }

    if (state is NotificationsError) {
      return ErrorView(
        title: loc.notificationsLoadError,
        message: state.message,
        retryLabel: loc.retry,
        onRetry: () => _refresh(context),
      );
    }

    if (state is! NotificationsLoaded) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: state.notifications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 80, 16, 16),
              children: [
                EmptyView(
                  icon: Icons.notifications_none_rounded,
                  title: loc.noNotifications,
                  message: loc.noNotificationsMessage,
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
              children: [
                if (state.hasUnread) ...[
                  Text(
                    loc.unreadNotifications(state.unreadCount),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final notification in state.notifications) ...[
                  NotificationCard(
                    notification: notification,
                    onTap: () => _openNotification(context, notification),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

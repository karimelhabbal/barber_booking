import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/empty_view.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:barber_booking/features/notifications/presentation/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared notifications screen for customers, owners and barbers.
///
/// The screen is role agnostic: the caller only supplies the authenticated
/// user id used to scope the notifications, so there is no per-role screen.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.recipientId});

  /// Id of the user the notifications belong to.
  final String recipientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()
        ..loadNotifications(recipientId: recipientId),
      child: _NotificationsView(recipientId: recipientId),
    );
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
                    onTap: () => context.read<NotificationsCubit>().markAsRead(
                      notification.id,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

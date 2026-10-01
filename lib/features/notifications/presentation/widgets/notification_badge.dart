import 'package:barber_booking/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps [child] (usually a notification icon) with the current unread count.
///
/// The count comes from the single global [NotificationsCubit], so every role
/// shows the same badge without duplicating state.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = state is NotificationsLoaded
            ? state.unreadCount
            : 0;

        if (unreadCount <= 0) {
          return child;
        }

        return Badge(
          label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
          child: child,
        );
      },
    );
  }
}

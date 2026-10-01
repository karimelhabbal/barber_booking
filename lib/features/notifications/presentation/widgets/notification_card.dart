import 'package:barber_booking/features/notifications/domain/entities/notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact, reusable notification row shared by every role.
///
/// Unread notifications get a tinted card, a highlighted type icon and an
/// unread dot; read notifications use the default surface with muted text.
/// Only theme colour tokens are used, no new colours are introduced.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !notification.isRead;

    return Card(
      margin: EdgeInsets.zero,
      color: isUnread
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnread
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(notification.type),
                  size: 20,
                  color: isUnread
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isUnread
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.yMMMd().add_Hm().format(
                        notification.createdAt.toLocal(),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return Icons.event_available_outlined;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle_outline_rounded;
      case NotificationType.bookingRejected:
        return Icons.cancel_outlined;
      case NotificationType.bookingCancelled:
        return Icons.event_busy_outlined;
      case NotificationType.bookingCompleted:
        return Icons.done_all_rounded;
      case NotificationType.bookingNoShow:
        return Icons.warning_amber_outlined;
      case NotificationType.appointmentReminder:
        return Icons.alarm_outlined;
      case NotificationType.scheduleChanged:
        return Icons.schedule_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }
}

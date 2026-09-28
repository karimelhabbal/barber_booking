part of '../barber_dashboard_page.dart';

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onStatusChange});

  final Booking booking;
  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    final canChangeStatus =
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;

    final dateLabel = _bookingDateLabel(context, booking.bookingDate, loc);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    booking.startTime,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          booking.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canChangeStatus)
                        PopupMenuButton<BookingStatus>(
                          tooltip: loc.bookingActions,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (status) {
                            onStatusChange(booking.id, status);
                          },
                          itemBuilder: (context) {
                            final statuses =
                                booking.status == BookingStatus.pending
                                ? const [
                                    BookingStatus.confirmed,
                                    BookingStatus.cancelled,
                                  ]
                                : const [
                                    BookingStatus.completed,
                                    BookingStatus.noShow,
                                  ];

                            return statuses
                                .map(
                                  (status) => PopupMenuItem<BookingStatus>(
                                    value: status,
                                    child: Text(_statusActionText(status, loc)),
                                  ),
                                )
                                .toList();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateLabel · ${booking.startTime} – ${booking.endTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusChip(status: booking.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bookingDateLabel(
    BuildContext context,
    DateTime bookingDate,
    AppLocalizations loc,
  ) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final date = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

    final difference = date.difference(today).inDays;

    if (difference == 0) {
      return loc.today;
    }

    if (difference == 1) {
      return loc.tomorrow;
    }

    if (difference == 2) {
      return loc.dayAfterTomorrow;
    }

    if (difference > 2 && difference <= 7) {
      final locale = Localizations.localeOf(context).toString();

      final weekday = DateFormat('EEEE', locale).format(date);

      return loc.nextWeekday(weekday);
    }

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _statusActionText(BookingStatus status, AppLocalizations loc) {
    switch (status) {
      case BookingStatus.confirmed:
        return loc.confirm;
      case BookingStatus.cancelled:
        return loc.rejectCancel;
      case BookingStatus.completed:
        return loc.complete;
      case BookingStatus.noShow:
        return loc.markNoShow;
      case BookingStatus.pending:
        return loc.pending;
    }
  }
}

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

    final canChangeStatus =
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;

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
                          tooltip: 'Actions',
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
                                    child: Text(_statusActionText(status)),
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
                    '${booking.startTime} • ${booking.endTime}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  String _statusActionText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirm';
      case BookingStatus.cancelled:
        return 'Reject / cancel';
      case BookingStatus.completed:
        return 'Complete';
      case BookingStatus.noShow:
        return 'Mark no-show';
      case BookingStatus.pending:
        return 'Pending';
    }
  }
}

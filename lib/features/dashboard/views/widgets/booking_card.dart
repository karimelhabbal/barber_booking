part of '../barber_dashboard_page.dart';

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onStatusChange});

  final Booking booking;
  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(booking.startTime, style: const TextStyle(fontSize: 12)),
        ),
        title: Text(booking.customerName),
        subtitle: Text(
          '${booking.serviceName} • '
          '${booking.startTime} - ${booking.endTime}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(status: booking.status),
            if (booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed)
              PopupMenuButton<BookingStatus>(
                onSelected: (status) {
                  onStatusChange(booking.id, status);
                },
                itemBuilder: (context) {
                  final statuses = booking.status == BookingStatus.pending
                      ? const [BookingStatus.confirmed, BookingStatus.cancelled]
                      : const [BookingStatus.completed, BookingStatus.noShow];

                  return statuses
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(_statusActionText(status)),
                        ),
                      )
                      .toList();
                },
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

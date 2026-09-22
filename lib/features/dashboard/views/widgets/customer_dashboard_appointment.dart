part of '../customer_dashboard_page.dart';

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusChip(
                status: booking.status.name,
                label: _statusLabel(booking.status, loc),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(booking.barberName)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_dateLabel(booking.bookingDate)} • ${booking.startTime} - ${booking.endTime}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.serviceDurationMinutes} ${loc.minutes} • ${booking.servicePrice.toStringAsFixed(2)} EGP',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(BookingStatus status, AppLocalizations loc) {
    switch (status) {
      case BookingStatus.pending:
        return loc.pending;
      case BookingStatus.confirmed:
        return loc.confirmed;
      case BookingStatus.completed:
        return loc.completed;
      case BookingStatus.cancelled:
        return loc.cancelled;
      case BookingStatus.noShow:
        return loc.noShow;
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

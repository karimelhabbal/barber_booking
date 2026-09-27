part of '../customer_dashboard_page.dart';

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final date = booking.bookingDate;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  date.day.toString().padLeft(2, '0'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  date.month.toString().padLeft(2, '0'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      status: booking.status.name,
                      label: _statusLabel(booking.status, loc),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.barberName,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_dateLabel(date)} • ${booking.startTime} - ${booking.endTime}',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${booking.serviceDurationMinutes} ${loc.minutes} • ${booking.servicePrice.toStringAsFixed(2)} EGP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

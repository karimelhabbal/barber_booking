part of '../barber_dashboard_page.dart';

class _BarberDashboardBody extends StatelessWidget {
  const _BarberDashboardBody({
    required this.barberId,
    required this.barberName,
    required this.shop,
    required this.bookings,
    required this.onStatusChange,
  });

  final String barberId;
  final String barberName;
  final BarberShop shop;
  final List<Booking> bookings;
  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final activeBookings =
        bookings
            .where((booking) => booking.status != BookingStatus.cancelled)
            .toList()
          ..sort(_compareBookings);

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    todayStart.add(const Duration(days: 1));

    final todayBookings = activeBookings.where((booking) {
      return _isSameDay(booking.bookingDate, todayStart);
    }).toList();

    final pendingCount = todayBookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;

    final confirmedCount = todayBookings
        .where((booking) => booking.status == BookingStatus.confirmed)
        .length;

    final completedCount = todayBookings
        .where((booking) => booking.status == BookingStatus.completed)
        .length;

    final now = DateTime.now();

    final upcomingBookings = activeBookings.where((booking) {
      if (booking.status == BookingStatus.completed) {
        return false;
      }

      final bookingDate = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
      );

      final startMinutes = _timeToMinutes(booking.startTime);

      final bookingStart = bookingDate.add(Duration(minutes: startMinutes));

      return !bookingStart.isBefore(now);
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        return context.read<BookingCubit>().loadBarberBookings(
          barberId: barberId,
        );
      },
      child: SafeArea(
        top: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _WelcomeCard(barberName: barberName, shopName: shop.name),
            const SizedBox(height: 24),
            Text(
              loc.today,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _SummaryGrid(
              total: todayBookings.length,
              pending: pendingCount,
              confirmed: confirmedCount,
              completed: completedCount,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.upcomingBookings,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (upcomingBookings.isNotEmpty)
                  Text(
                    '${upcomingBookings.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcomingBookings.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        loc.noUpcomingBookings,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.noRemainingAppointmentsToday,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...upcomingBookings.map(
                (booking) => _BookingCard(
                  booking: booking,
                  onStatusChange: onStatusChange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime value, DateTime day) {
    return value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }

  static int _compareBookings(Booking a, Booking b) {
    final aDate = DateTime(
      a.bookingDate.year,
      a.bookingDate.month,
      a.bookingDate.day,
    );

    final bDate = DateTime(
      b.bookingDate.year,
      b.bookingDate.month,
      b.bookingDate.day,
    );

    final dateComparison = aDate.compareTo(bDate);

    if (dateComparison != 0) {
      return dateComparison;
    }

    return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
  }

  static int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return (hour * 60) + minute;
  }
}

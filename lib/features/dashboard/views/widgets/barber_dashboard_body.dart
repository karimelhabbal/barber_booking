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
    final activeBookings =
        bookings
            .where((booking) => booking.status != BookingStatus.cancelled)
            .toList()
          ..sort(
            (a, b) =>
                _timeToMinutes(a.startTime)
                    .compareTo(_timeToMinutes(b.startTime)),
          );

    final pendingCount = activeBookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;
    final confirmedCount = activeBookings
        .where((booking) => booking.status == BookingStatus.confirmed)
        .length;
    final completedCount = activeBookings
        .where((booking) => booking.status == BookingStatus.completed)
        .length;
    final now = TimeOfDay.now();
    final nowMinutes = (now.hour * 60) + now.minute;
    final upcomingBookings = activeBookings.where((booking) {
      return _timeToMinutes(booking.startTime) >= nowMinutes &&
          booking.status != BookingStatus.completed;
    }).toList();

    return RefreshIndicator(
      onRefresh: () {
        return context.read<BookingCubit>().loadBarberBookingsForDate(
          barberId: barberId,
          date: DateTime.now(),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeCard(barberName: barberName, shopName: shop.name),
          const SizedBox(height: 16),
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _SummaryGrid(
            total: activeBookings.length,
            pending: pendingCount,
            confirmed: confirmedCount,
            completed: completedCount,
          ),
          const SizedBox(height: 24),
          Text(
            'Upcoming bookings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (upcomingBookings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No upcoming bookings today.',
                    textAlign: TextAlign.center,
                  ),
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
    );
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

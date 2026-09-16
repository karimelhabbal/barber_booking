part of '../barber_dashboard_page.dart';

class _BarberDashboardScaffold extends StatelessWidget {
  const _BarberDashboardScaffold({
    required this.barberId,
    required this.barberName,
    required this.shop,
    required this.onLogout,
  });

  final String barberId;
  final String barberName;
  final BarberShop shop;
  final Future<void> Function(BuildContext context) onLogout;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingCubit>()
        ..loadBarberBookingsForDate(barberId: barberId, date: DateTime.now()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Barber Dashboard'),
          actions: [
            IconButton(
              onPressed: () => onLogout(context),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingCancelled || state is BookingStatusUpdated) {
              context.read<BookingCubit>().loadBarberBookingsForDate(
                barberId: barberId,
                date: DateTime.now(),
              );
            }
          },
          builder: (context, state) {
            if (state is BookingLoading ||
                state is BookingInitial ||
                state is BookingCancelling ||
                state is BookingStatusUpdating) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookingError) {
              return RefreshIndicator(
                onRefresh: () {
                  return context.read<BookingCubit>().loadBarberBookingsForDate(
                    barberId: barberId,
                    date: DateTime.now(),
                  );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 100),
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text(
                      'Pull down to try again.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (state is! BookingLoaded) {
              return const SizedBox.shrink();
            }

            return _BarberDashboardBody(
              barberId: barberId,
              barberName: barberName,
              shop: shop,
              bookings: state.bookings,
              onStatusChange: (bookingId, status) {
                switch (status) {
                  case BookingStatus.confirmed:
                    return context.read<BookingCubit>().confirmBooking(
                      bookingId: bookingId,
                    );
                  case BookingStatus.cancelled:
                    return context.read<BookingCubit>().rejectBooking(
                      bookingId: bookingId,
                    );
                  case BookingStatus.completed:
                    return context.read<BookingCubit>().completeBooking(
                      bookingId: bookingId,
                    );
                  case BookingStatus.noShow:
                    return context.read<BookingCubit>().markNoShow(
                      bookingId: bookingId,
                    );
                  case BookingStatus.pending:
                    return Future<void>.value();
                }
              },
            );
          },
        ),
      ),
    );
  }
}

part of '../barber_dashboard_page.dart';

/// Dashboard section of the barber workspace.
///
/// Keeps the existing booking loading and status handling of the barber
/// dashboard; only the standalone navigation chrome is replaced by the
/// workspace shell (logout now lives in the Settings section).
class BarberDashboardTab extends StatelessWidget {
  const BarberDashboardTab({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.shop,
  });

  final String barberId;
  final String barberName;
  final BarberShop shop;

  void _openNotifications(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(recipientId: authState.user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) =>
          getIt<BookingCubit>()..loadBarberBookings(barberId: barberId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.barberDashboard),
          actions: [
            IconButton(
              onPressed: () => _openNotifications(context),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: loc.notifications,
            ),
          ],
        ),
        body: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingCancelled || state is BookingStatusUpdated) {
              context.read<BookingCubit>().loadBarberBookings(
                barberId: barberId,
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
                  return context.read<BookingCubit>().loadBarberBookings(
                    barberId: barberId,
                  );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 100),
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(loc.pullDownToTryAgain, textAlign: TextAlign.center),
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
                      cancelledBy: CancelledBy.barber,
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

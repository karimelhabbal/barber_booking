import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerBookingsPage extends StatelessWidget {
  const OwnerBookingsPage({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingCubit>()..loadOwnerBookings(shopId: shopId),
      child: _OwnerBookingsView(shopId: shopId),
    );
  }
}

class _OwnerBookingsView extends StatelessWidget {
  const _OwnerBookingsView({required this.shopId});

  final String shopId;

  Future<void> _refresh(BuildContext context) {
    return context.read<BookingCubit>().loadOwnerBookings(shopId: shopId);
  }

  Future<void> _updateStatus(
    BuildContext context,
    String bookingId,
    BookingStatus status,
  ) {
    final cubit = context.read<BookingCubit>();

    switch (status) {
      case BookingStatus.confirmed:
        return cubit.confirmBooking(bookingId: bookingId);
      case BookingStatus.cancelled:
        return cubit.rejectBooking(bookingId: bookingId);
      case BookingStatus.completed:
        return cubit.completeBooking(bookingId: bookingId);
      case BookingStatus.noShow:
        return cubit.markNoShow(bookingId: bookingId);
      case BookingStatus.pending:
        return Future<void>.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.shopBookings)),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled || state is BookingStatusUpdated) {
            _refresh(context);
          }
        },
        builder: (context, state) {
          if (state is BookingLoading ||
              state is BookingCancelling ||
              state is BookingStatusUpdating) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingError) {
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (state is BookingLoaded) {
            if (state.bookings.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 160),
                    Center(child: Text(loc.noBookingsYet)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = state.bookings[index];
                  return _OwnerBookingCard(
                    booking: booking,
                    loc: loc,
                    onStatusChange: (status) =>
                        _updateStatus(context, booking.id, status),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OwnerBookingCard extends StatelessWidget {
  const _OwnerBookingCard({
    required this.booking,
    required this.loc,
    required this.onStatusChange,
  });

  final Booking booking;
  final AppLocalizations loc;
  final Future<void> Function(BookingStatus status) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final canUpdate =
        booking.status == BookingStatus.pending ||
        booking.status == BookingStatus.confirmed;

    return Card(
      child: ListTile(
        title: Text(booking.serviceName),
        subtitle: Text(
          '${loc.customer}: ${booking.customerName}\n'
          '${loc.barber}: ${booking.barberName}\n'
          '${_formatDate(booking.bookingDate)} | '
          '${booking.startTime} - ${booking.endTime}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_statusText(booking.status)),
            if (canUpdate)
              PopupMenuButton<BookingStatus>(
                onSelected: onStatusChange,
                itemBuilder: (context) {
                  final statuses = booking.status == BookingStatus.pending
                      ? const [BookingStatus.confirmed, BookingStatus.cancelled]
                      : const [BookingStatus.completed, BookingStatus.noShow];

                  return statuses
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(_actionText(status)),
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

  String _statusText(BookingStatus status) {
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

  String _actionText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return loc.confirmAction;
      case BookingStatus.cancelled:
        return loc.rejectCancelAction;
      case BookingStatus.completed:
        return loc.completeAction;
      case BookingStatus.noShow:
        return loc.markNoShowAction;
      case BookingStatus.pending:
        return loc.pending;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

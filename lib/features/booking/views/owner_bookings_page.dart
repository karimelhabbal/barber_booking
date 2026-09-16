import 'package:barber_booking/core/di/injection.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Shop bookings')),
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
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('No bookings for this shop.')),
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
    required this.onStatusChange,
  });

  final Booking booking;
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
          'Customer: ${booking.customerName}\n'
          'Barber: ${booking.barberName}\n'
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
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No-show';
    }
  }

  String _actionText(BookingStatus status) {
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/app_card.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/core/widgets/status_chip.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Minimal booking-details destination for notification taps.
///
/// Reuses the existing [BookingCubit.loadBooking] / repository / model — no
/// parallel booking architecture. Rendered for every role; Firestore rules
/// decide which booking the signed-in user may read.
class BookingDetailsPage extends StatelessWidget {
  const BookingDetailsPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingCubit>()..loadBooking(bookingId: bookingId),
      child: _BookingDetailsView(bookingId: bookingId),
    );
  }
}

class _BookingDetailsView extends StatelessWidget {
  const _BookingDetailsView({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.bookingDetails)),
      body: SafeArea(
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            if (state is BookingInitial || state is BookingLoading) {
              return const LoadingView();
            }

            if (state is BookingError) {
              return ErrorView(
                title: loc.loadBookingsError,
                message: state.message,
                retryLabel: loc.retry,
                onRetry: () => context.read<BookingCubit>().loadBooking(
                  bookingId: bookingId,
                ),
              );
            }

            if (state is BookingLoaded && state.bookings.isNotEmpty) {
              return _details(context, loc, state.bookings.first);
            }

            return ErrorView(
              title: loc.loadBookingsError,
              message: loc.bookingNotFound,
              retryLabel: loc.retry,
              onRetry: () => context.read<BookingCubit>().loadBooking(
                bookingId: bookingId,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _details(BuildContext context, AppLocalizations loc, Booking booking) {
    final date = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).toString(),
    ).format(booking.bookingDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(
                    status: booking.status.name,
                    label: _statusText(booking.status, loc),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(loc.barber, booking.barberName),
              const SizedBox(height: 8),
              _row(loc.customer, booking.customerName),
              const SizedBox(height: 8),
              _row(loc.date, date),
              const SizedBox(height: 8),
              _row(loc.time, '${booking.startTime} - ${booking.endTime}'),
              const SizedBox(height: 8),
              _row(loc.price, '${booking.servicePrice.toStringAsFixed(2)} EGP'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text('$label:')),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _statusText(BookingStatus status, AppLocalizations loc) {
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
}

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/theme/app_theme.dart';
import 'package:barber_booking/core/widgets/app_card.dart';
import 'package:barber_booking/core/widgets/empty_view.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/core/widgets/status_chip.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerBookingsPage extends StatelessWidget {
  const CustomerBookingsPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BookingCubit>()..loadCustomerBookings(customerId: customerId),
      child: _CustomerBookingsView(customerId: customerId),
    );
  }
}

class _CustomerBookingsView extends StatelessWidget {
  const _CustomerBookingsView({required this.customerId});

  final String customerId;

  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    final loc = AppLocalizations.of(context)!;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.cancelBookingQuestion),
        content: Text(loc.bookingCancelledMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.keep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );

    if (shouldCancel == true && context.mounted) {
      await context.read<BookingCubit>().cancelBooking(bookingId: booking.id);
    }
  }

  Future<void> _refresh(BuildContext context) {
    return context.read<BookingCubit>().loadCustomerBookings(
      customerId: customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.myBookings),
        backgroundColor: AppColors.background,
      ),
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            _refresh(context);
          }
        },
        builder: (context, state) {
          if (state is BookingLoading || state is BookingCancelling) {
            return LoadingView(message: loc.loadingBookings);
          }

          if (state is BookingError) {
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    title: loc.loadBookingsError,
                    message: state.message,
                    onRetry: () => _refresh(context),
                    retryLabel: loc.retry,
                  ),
                ],
              ),
            );
          }

          if (state is BookingLoaded) {
            final upcomingBookings = state.bookings
                .where(_isUpcomingBooking)
                .toList();
            final historyBookings = state.bookings
                .where(
                  (booking) =>
                      booking.status == BookingStatus.cancelled ||
                      booking.status == BookingStatus.completed ||
                      booking.status == BookingStatus.noShow,
                )
                .toList();

            if (state.bookings.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 120),
                    EmptyView(
                      title: loc.noBookingsYet,
                      message: loc.bookingsEmptyMessage,
                      icon: Icons.event_note_outlined,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    loc.upcoming,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (upcomingBookings.isEmpty)
                    EmptyView(
                      title: loc.noUpcomingBookings,
                      message: loc.noUpcomingAppointments,
                      icon: Icons.calendar_today_outlined,
                    )
                  else
                    ...upcomingBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingHistoryCard(
                          booking: booking,
                          onCancel: booking.status == BookingStatus.pending
                              ? () => _cancelBooking(context, booking)
                              : null,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    loc.history,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (historyBookings.isEmpty)
                    EmptyView(
                      title: loc.noBookingHistory,
                      message: loc.pastAppointments,
                      icon: Icons.history_outlined,
                    )
                  else
                    ...historyBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingHistoryCard(booking: booking),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  bool _isUpcomingBooking(Booking booking) {
    if (booking.status != BookingStatus.pending &&
        booking.status != BookingStatus.confirmed) {
      return false;
    }

    final timeParts = booking.startTime.split(':');
    if (timeParts.length != 2) return false;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return false;

    final scheduledDateTime = DateTime(
      booking.bookingDate.year,
      booking.bookingDate.month,
      booking.bookingDate.day,
      hour,
      minute,
    );

    return scheduledDateTime.isAfter(DateTime.now());
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({required this.booking, this.onCancel});

  final Booking booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(
                status: booking.status.name,
                label: _statusText(booking.status, loc),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: loc.barber, value: booking.barberName),
          const SizedBox(height: 8),
          _InfoRow(label: loc.date, value: _formatDate(booking.bookingDate)),
          const SizedBox(height: 8),
          _InfoRow(
            label: loc.time,
            value: '${booking.startTime} - ${booking.endTime}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: loc.price,
            value: '${booking.servicePrice.toStringAsFixed(2)} EGP',
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(loc.cancelBooking),
            ),
          ],
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

import 'package:barber_booking/core/di/injection.dart';
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
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text('This booking will be cancelled.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My bookings'),
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
            return const LoadingView(message: 'Loading bookings...');
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
                    title: 'Unable to load bookings.',
                    message: state.message,
                    onRetry: () => _refresh(context),
                  ),
                ],
              ),
            );
          }

          if (state is BookingLoaded) {
            final upcomingBookings = state.bookings
                .where((booking) => _isUpcomingBooking(booking))
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
                  children: const [
                    SizedBox(height: 120),
                    EmptyView(
                      title: 'No bookings yet.',
                      message:
                          'Your upcoming and past bookings will appear here.',
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
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (upcomingBookings.isEmpty)
                    const EmptyView(
                      title: 'No upcoming bookings.',
                      message: 'There are no upcoming appointments right now.',
                      icon: Icons.calendar_today_outlined,
                    )
                  else ...[
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
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (historyBookings.isEmpty)
                    const EmptyView(
                      title: 'No booking history.',
                      message: 'Past appointments will appear here.',
                      icon: Icons.history_outlined,
                    )
                  else ...[
                    ...historyBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingHistoryCard(booking: booking),
                      ),
                    ),
                  ],
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
    if (timeParts.length != 2) {
      return false;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      return false;
    }

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
                label: _statusText(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Barber', value: booking.barberName),
          const SizedBox(height: 8),
          _InfoRow(label: 'Date', value: _formatDate(booking.bookingDate)),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Time',
            value: '${booking.startTime} - ${booking.endTime}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Price',
            value: '${booking.servicePrice.toStringAsFixed(2)} EGP',
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel booking'),
            ),
          ],
        ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
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

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/status_chip.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Appointments section of the barber workspace.
///
/// Reuses [BookingCubit] (through DI) and the existing booking status actions,
/// adding only a date selector on top of the day scoped barber bookings.
class BarberAppointmentsPage extends StatelessWidget {
  const BarberAppointmentsPage({super.key, required this.barberId});

  final String barberId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingCubit>(),
      child: _BarberAppointmentsView(barberId: barberId),
    );
  }
}

class _BarberAppointmentsView extends StatefulWidget {
  const _BarberAppointmentsView({required this.barberId});

  final String barberId;

  @override
  State<_BarberAppointmentsView> createState() =>
      _BarberAppointmentsViewState();
}

class _BarberAppointmentsViewState extends State<_BarberAppointmentsView> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    _selectedDate = DateUtils.dateOnly(DateTime.now());

    _loadBookings();
  }

  Future<void> _loadBookings() {
    return context.read<BookingCubit>().loadBarberBookingsForDate(
      barberId: widget.barberId,
      date: _selectedDate,
    );
  }

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) {
      return;
    }

    final date = DateUtils.dateOnly(picked);

    if (DateUtils.isSameDay(date, _selectedDate)) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });

    await _loadBookings();
  }

  Future<void> _changeStatus(String bookingId, BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return context.read<BookingCubit>().confirmBooking(
          bookingId: bookingId,
        );
      case BookingStatus.cancelled:
        return context.read<BookingCubit>().rejectBooking(bookingId: bookingId);
      case BookingStatus.completed:
        return context.read<BookingCubit>().completeBooking(
          bookingId: bookingId,
        );
      case BookingStatus.noShow:
        return context.read<BookingCubit>().markNoShow(bookingId: bookingId);
      case BookingStatus.pending:
        return Future<void>.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingStatusUpdated || state is BookingCancelled) {
          _loadBookings();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(loc.appointments)),
        body: SafeArea(
          child: BlocBuilder<BookingCubit, BookingState>(
            builder: (context, state) {
              if (state is BookingInitial ||
                  state is BookingLoading ||
                  state is BookingStatusUpdating ||
                  state is BookingCancelling) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = state is BookingLoaded
                  ? _sortedBookings(state.bookings)
                  : const <Booking>[];

              return RefreshIndicator(
                onRefresh: _loadBookings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 24),
                  children: [
                    _DateSelector(date: _selectedDate, onTap: _pickDate),
                    const SizedBox(height: 16),
                    if (state is BookingError)
                      _AppointmentsMessage(
                        icon: Icons.error_outline_rounded,
                        title: state.message,
                        onRetry: _loadBookings,
                      )
                    else ...[
                      Text(
                        loc.bookingsCount(bookings.length),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (bookings.isEmpty)
                        _AppointmentsMessage(
                          icon: Icons.event_busy_outlined,
                          title: loc.noAppointmentsForDate,
                          message: loc.noAppointmentsForDateMessage,
                        )
                      else
                        for (final booking in bookings)
                          _AppointmentCard(
                            booking: booking,
                            onStatusChange: _changeStatus,
                          ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Booking> _sortedBookings(List<Booking> bookings) {
    return [...bookings]..sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return (hour * 60) + minute;
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().format(date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentsMessage extends StatelessWidget {
  const _AppointmentsMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final description = message;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => onRetry!(),
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.booking,
    required this.onStatusChange,
  });

  final Booking booking;
  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final actions = _actionsFor(loc);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${booking.startTime} - ${booking.endTime}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  status: booking.status.name,
                  label: _statusLabel(loc, booking.status),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CardDetail(
              icon: Icons.person_outline_rounded,
              text: booking.customerName,
            ),
            const SizedBox(height: 6),
            _CardDetail(
              icon: Icons.content_cut_rounded,
              text: booking.serviceName,
            ),
            if (actions.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final action in actions)
                      TextButton.icon(
                        onPressed: () =>
                            onStatusChange(booking.id, action.status),
                        icon: Icon(action.icon, size: 18),
                        label: Text(action.label),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_AppointmentAction> _actionsFor(AppLocalizations loc) {
    switch (booking.status) {
      case BookingStatus.pending:
        return [
          _AppointmentAction(
            icon: Icons.check_rounded,
            label: loc.confirmAction,
            status: BookingStatus.confirmed,
          ),
          _AppointmentAction(
            icon: Icons.close_rounded,
            label: loc.rejectCancelAction,
            status: BookingStatus.cancelled,
          ),
        ];
      case BookingStatus.confirmed:
        return [
          _AppointmentAction(
            icon: Icons.done_all_rounded,
            label: loc.completeAction,
            status: BookingStatus.completed,
          ),
          _AppointmentAction(
            icon: Icons.person_off_outlined,
            label: loc.markNoShowAction,
            status: BookingStatus.noShow,
          ),
        ];
      case BookingStatus.completed:
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return const [];
    }
  }

  String _statusLabel(AppLocalizations loc, BookingStatus status) {
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

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _AppointmentAction {
  const _AppointmentAction({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final BookingStatus status;
}





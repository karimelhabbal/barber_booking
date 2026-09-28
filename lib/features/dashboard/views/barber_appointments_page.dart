import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/status_chip.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Appointments workspace of the barber.
///
/// Loads the barber's bookings once and filters them locally by the selected
/// date. This allows the date strip to indicate which days contain bookings
/// without issuing a Firestore request for every date selection.
class BarberAppointmentsPage extends StatelessWidget {
  const BarberAppointmentsPage({super.key, required this.barberId});

  final String barberId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BookingCubit>()..loadBarberBookings(barberId: barberId),
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
  }

  Future<void> _loadBookings() {
    return context.read<BookingCubit>().loadBarberBookings(
      barberId: widget.barberId,
    );
  }

  Future<void> _selectDate(DateTime date) async {
    final normalizedDate = DateUtils.dateOnly(date);

    if (DateUtils.isSameDay(normalizedDate, _selectedDate)) {
      return;
    }

    setState(() {
      _selectedDate = normalizedDate;
    });
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

    await _selectDate(picked);
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
        appBar: AppBar(
          title: Text(loc.appointments),
          actions: [
            IconButton(
              onPressed: _pickDate,
              tooltip: loc.date,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<BookingCubit, BookingState>(
            builder: (context, state) {
              if (state is BookingInitial ||
                  state is BookingLoading ||
                  state is BookingStatusUpdating ||
                  state is BookingCancelling) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is BookingError) {
                return RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _SelectedDateHeader(
                        date: _selectedDate,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      _AppointmentsMessage(
                        icon: Icons.error_outline_rounded,
                        title: state.message,
                        onRetry: _loadBookings,
                      ),
                    ],
                  ),
                );
              }

              if (state is! BookingLoaded) {
                return const SizedBox.shrink();
              }

              final allBookings = state.bookings;

              final bookingsForSelectedDate = allBookings
                  .where(
                    (booking) =>
                        DateUtils.isSameDay(booking.bookingDate, _selectedDate),
                  )
                  .toList();

              final bookings = _sortedBookings(bookingsForSelectedDate);

              return RefreshIndicator(
                onRefresh: _loadBookings,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _SelectedDateHeader(date: _selectedDate, onTap: _pickDate),
                    const SizedBox(height: 16),
                    _DateStrip(
                      selectedDate: _selectedDate,
                      bookingDates: allBookings
                          .map((booking) => booking.bookingDate)
                          .toList(),
                      onDateSelected: _selectDate,
                    ),
                    const SizedBox(height: 20),
                    _AppointmentsSummary(bookings: bookings),
                    const SizedBox(height: 24),
                    _AppointmentsSectionHeader(
                      date: _selectedDate,
                      count: bookings.length,
                    ),
                    const SizedBox(height: 14),
                    if (bookings.isEmpty)
                      _AppointmentsMessage(
                        icon: Icons.event_busy_outlined,
                        title: loc.noAppointmentsForDate,
                        message: loc.noAppointmentsForDateMessage,
                      )
                    else
                      _AppointmentsTimeline(
                        bookings: bookings,
                        onStatusChange: _changeStatus,
                      ),
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

class _SelectedDateHeader extends StatelessWidget {
  const _SelectedDateHeader({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    final fullDate = DateFormat.yMMMMEEEEd(locale).format(date);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullDate,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selectedDate,
    required this.bookingDates,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<DateTime> bookingDates;
  final Future<void> Function(DateTime date) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = DateUtils.dateOnly(DateTime.now());

    final dates = List<DateTime>.generate(
      7,
      (index) => selectedDate.add(Duration(days: index - 3)),
    );

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];

          final isSelected = DateUtils.isSameDay(date, selectedDate);

          final isToday = DateUtils.isSameDay(date, today);

          final hasBookings = bookingDates.any(
            (bookingDate) => DateUtils.isSameDay(bookingDate, date),
          );

          final weekday = DateFormat.E(locale).format(date);

          return _DateStripItem(
            date: date,
            weekday: weekday,
            isSelected: isSelected,
            isToday: isToday,
            hasBookings: hasBookings,
            onTap: () => onDateSelected(date),
            theme: theme,
          );
        },
      ),
    );
  }
}

class _DateStripItem extends StatelessWidget {
  const _DateStripItem({
    required this.date,
    required this.weekday,
    required this.isSelected,
    required this.isToday,
    required this.hasBookings,
    required this.onTap,
    required this.theme,
  });

  final DateTime date;
  final String weekday;
  final bool isSelected;
  final bool isToday;
  final bool hasBookings;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;

    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    final indicatorColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.primary;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Today indicator: a short line.
                      if (isToday)
                        Container(
                          width: 12,
                          height: 2,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                      if (isToday && hasBookings) const SizedBox(width: 5),

                      // Booking indicator: a small dot.
                      if (hasBookings)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentsSummary extends StatelessWidget {
  const _AppointmentsSummary({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final pending = bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;

    final confirmed = bookings
        .where((booking) => booking.status == BookingStatus.confirmed)
        .length;

    final completed = bookings
        .where((booking) => booking.status == BookingStatus.completed)
        .length;

    return Row(
      children: [
        Expanded(
          child: _SummaryItem(
            value: bookings.length,
            label: loc.total,
            icon: Icons.event_note_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            value: pending,
            label: loc.pending,
            icon: Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            value: confirmed,
            label: loc.confirmed,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryItem(
            value: completed,
            label: loc.completed,
            icon: Icons.done_all_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsSectionHeader extends StatelessWidget {
  const _AppointmentsSectionHeader({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            loc.bookingsCount(count),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          DateFormat.MMMd(Localizations.localeOf(context).toString())
              .format(date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AppointmentsTimeline extends StatelessWidget {
  const _AppointmentsTimeline({
    required this.bookings,
    required this.onStatusChange,
  });

  final List<Booking> bookings;

  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < bookings.length; index++)
          _TimelineAppointment(
            booking: bookings[index],
            isLast: index == bookings.length - 1,
            onStatusChange: onStatusChange,
          ),
      ],
    );
  }
}

class _TimelineAppointment extends StatelessWidget {
  const _TimelineAppointment({
    required this.booking,
    required this.isLast,
    required this.onStatusChange,
  });

  final Booking booking;
  final bool isLast;

  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Column(
            children: [
              Text(
                booking.startTime,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                booking.endTime,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: _statusColor(context, booking.status),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 150,
                  margin: const EdgeInsets.only(top: 6),
                  color: colorScheme.outlineVariant,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AppointmentCard(
            booking: booking,
            onStatusChange: onStatusChange,
            loc: loc,
          ),
        ),
      ],
    );
  }

  Color _statusColor(BuildContext context, BookingStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case BookingStatus.pending:
        return colorScheme.tertiary;

      case BookingStatus.confirmed:
        return colorScheme.primary;

      case BookingStatus.completed:
        return colorScheme.secondary;

      case BookingStatus.cancelled:
        return colorScheme.error;

      case BookingStatus.noShow:
        return colorScheme.error;
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.booking,
    required this.onStatusChange,
    required this.loc,
  });

  final Booking booking;

  final Future<void> Function(String bookingId, BookingStatus status)
  onStatusChange;

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _actionsFor();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: booking.status.name, label: _statusLabel()),
              ],
            ),
            const SizedBox(height: 8),
            _CardDetail(
              icon: Icons.content_cut_rounded,
              text: booking.serviceName,
            ),
            const SizedBox(height: 6),
            _CardDetail(
              icon: Icons.schedule_rounded,
              text: '${booking.startTime} – ${booking.endTime}',
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  alignment: WrapAlignment.end,
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
          ],
        ),
      ),
    );
  }

  List<_AppointmentAction> _actionsFor() {
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

  String _statusLabel() {
    switch (booking.status) {
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message!,
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
                icon: const Icon(Icons.refresh_rounded),
                label: Text(loc.retry),
              ),
            ],
          ],
        ),
      ),
    );
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

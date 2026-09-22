import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/barber/domain/entities/barber.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/booking/domain/entities/available_slot.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:barber_booking/features/booking/views/customer_bookings_page.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({
    super.key,
    required this.shop,
    required this.barber,
    required this.service,
  });

  final BarberShop shop;
  final Barber barber;
  final Service service;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingCubit>(),
      child: _BookingFlow(shop: shop, barber: barber, service: service),
    );
  }
}

class _BookingFlow extends StatefulWidget {
  const _BookingFlow({
    required this.shop,
    required this.barber,
    required this.service,
  });

  final BarberShop shop;
  final Barber barber;
  final Service service;

  @override
  State<_BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<_BookingFlow> {
  late DateTime _selectedDate;
  AvailableSlot? _selectedSlot;
  bool _isAvailabilityStale = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSlots();
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 365)),
      ),
    );

    if (date == null || !mounted) {
      return;
    }

    final dateChanged = !DateUtils.isSameDay(_selectedDate, date);

    setState(() {
      if (dateChanged) {
        _isAvailabilityStale = true;
      }

      _selectedDate = DateUtils.dateOnly(date);
      _selectedSlot = null;
    });

    if (dateChanged) {
      _loadSlots();
    }
  }

  void _loadSlots() {
    setState(() {
      _selectedSlot = null;
      _isAvailabilityStale = false;
    });

    context.read<BookingCubit>().loadAvailableSlots(
      barberId: widget.barber.id,
      date: _selectedDate,
      serviceDurationMinutes: widget.service.durationMinutes,
    );
  }

  void _createBooking() {
    final slot = _selectedSlot;
    final authState = context.read<AuthCubit>().state;
    final loc = AppLocalizations.of(context)!;

    if (slot == null) {
      return;
    }

    if (authState is! AuthAuthenticated ||
        authState.user.name == null ||
        authState.user.name!.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.customerProfileIncomplete)));
      return;
    }

    final now = DateTime.now();
    final booking = Booking(
      id: '',
      customerId: authState.user.id,
      shopId: widget.shop.id,
      barberId: widget.barber.id,
      serviceId: widget.service.id,
      bookingDate: _selectedDate,
      startTime: _formatTime(slot.start),
      endTime: _formatTime(slot.end),
      status: BookingStatus.pending,
      serviceName: widget.service.name,
      serviceDurationMinutes: widget.service.durationMinutes,
      servicePrice: widget.service.price,
      customerName: authState.user.name!.trim(),
      barberName: widget.barber.name,
      createdAt: now,
      updatedAt: now,
    );

    context.read<BookingCubit>().createBooking(booking: booking);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.bookNow)),
      body: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final isCreating = state is BookingCreating;
          final isCreated = state is BookingCreated;
          final slots = state is AvailabilityLoaded ? state.slots : const [];

          // Reserve the system navigation inset OUTSIDE the scroll viewport so
          // the confirmation card and its Confirm button can never sit in the
          // Android system navigation area, at any scroll position; adds
          // nothing on devices without bottom system insets.
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              Text(
                widget.service.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(loc.barber, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(widget.barber.name),
              const SizedBox(height: 16),
              Text(loc.date, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Card(
                child: ListTile(
                  title: Text(_formatDate(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: isCreating || isCreated ? null : _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    isCreating || isCreated || state is AvailabilityLoading
                    ? null
                    : _loadSlots,
                child: Text(loc.showAvailableSlots),
              ),
              const SizedBox(height: 16),
              Text(loc.time, style: Theme.of(context).textTheme.bodySmall),
              if (state is AvailabilityLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (state is BookingError) ...[
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
              ],
              if (state is AvailabilityLoaded && !_isAvailabilityStale) ...[
                const SizedBox(height: 16),
                if (slots.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        loc.noAvailableSlots,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) {
                      return ChoiceChip(
                        label: Text(
                          '${_formatTime(slot.start)} - ${_formatTime(slot.end)}',
                        ),
                        selected: _selectedSlot == slot,
                        onSelected: isCreating || isCreated
                            ? null
                            : (_) => setState(() => _selectedSlot = slot),
                      );
                    }).toList(),
                  ),
              ],
              if (_selectedSlot != null && !isCreated) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.confirmAppointment),
                        const SizedBox(height: 8),
                        Text(
                          widget.service.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(loc.barber),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.barber.name)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDate(_selectedDate)} ${loc.at} '
                          '${_formatTime(_selectedSlot!.start)} - '
                          '${_formatTime(_selectedSlot!.end)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.service.durationMinutes} ${loc.minutes}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(loc.price),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.service.price.toStringAsFixed(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: isCreating ? null : _createBooking,
                          child: Text(
                            isCreating ? loc.creating : loc.confirmBooking,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (state is BookingCreated) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(loc.bookingCreated, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final authState = context.read<AuthCubit>().state;

                            if (authState is! AuthAuthenticated) {
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerBookingsPage(
                                  customerId: authState.user.id,
                                ),
                              ),
                            );
                          },
                          child: Text(loc.myBookings),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: Text(loc.dashboard),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            ),
          );
        },
      ),
    );
  }
}

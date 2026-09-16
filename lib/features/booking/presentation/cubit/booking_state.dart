import 'package:equatable/equatable.dart';

import '../../domain/entities/available_slot.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

// ============================================================
// INITIAL
// ============================================================

class BookingInitial extends BookingState {
  const BookingInitial();
}

// ============================================================
// GENERAL LOADING
// ============================================================

class BookingLoading extends BookingState {
  const BookingLoading();
}

// ============================================================
// BOOKINGS LOADED
// ============================================================

class BookingLoaded extends BookingState {
  const BookingLoaded(this.bookings);

  final List<Booking> bookings;

  @override
  List<Object?> get props => [bookings];
}

// ============================================================
// CREATE BOOKING
// ============================================================

class BookingCreating extends BookingState {
  const BookingCreating();
}

class BookingCreated extends BookingState {
  const BookingCreated(this.booking);

  final Booking booking;

  @override
  List<Object?> get props => [booking];
}

// ============================================================
// CANCEL BOOKING
// ============================================================

class BookingCancelling extends BookingState {
  const BookingCancelling(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

class BookingCancelled extends BookingState {
  const BookingCancelled(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

class BookingStatusUpdating extends BookingState {
  const BookingStatusUpdating({required this.bookingId, required this.status});

  final String bookingId;
  final BookingStatus status;

  @override
  List<Object?> get props => [bookingId, status];
}

class BookingStatusUpdated extends BookingState {
  const BookingStatusUpdated({required this.bookingId, required this.status});

  final String bookingId;
  final BookingStatus status;

  @override
  List<Object?> get props => [bookingId, status];
}

// ============================================================
// AVAILABILITY
// ============================================================

class AvailabilityLoading extends BookingState {
  const AvailabilityLoading();
}

class AvailabilityLoaded extends BookingState {
  const AvailabilityLoaded({
    required this.date,
    required this.barberId,
    required this.serviceDurationMinutes,
    required this.slots,
  });

  final DateTime date;
  final String barberId;
  final int serviceDurationMinutes;
  final List<AvailableSlot> slots;

  @override
  List<Object?> get props => [date, barberId, serviceDurationMinutes, slots];
}

// ============================================================
// ERROR
// ============================================================

class BookingError extends BookingState {
  const BookingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

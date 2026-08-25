part of 'booking_bloc.dart';

abstract class BookingEvent {}

class CreateBookingEvent extends BookingEvent {
  // Add fields like barberId, time, customerId
}

class LoadBookingsEvent extends BookingEvent {}

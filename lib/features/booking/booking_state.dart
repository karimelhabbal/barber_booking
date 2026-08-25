part of 'booking_bloc.dart';

abstract class BookingState {}

class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}
class BookingLoaded extends BookingState {
  final List<dynamic> bookings;
  BookingLoaded({required this.bookings});
}
class BookingCreated extends BookingState {}
class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

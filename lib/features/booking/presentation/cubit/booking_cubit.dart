import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/get_available_slots.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required this._repository,
    required this._getAvailableSlots,
    required this._createBooking,
  }) : super(const BookingInitial());

  final BookingRepository _repository;
  final GetAvailableSlots _getAvailableSlots;
  final CreateBooking _createBooking;

  Future<void> loadCustomerBookings({required String customerId}) async {
    final trimmedCustomerId = customerId.trim();

    if (trimmedCustomerId.isEmpty) {
      emit(const BookingError('Customer ID cannot be empty.'));
      return;
    }

    emit(const BookingLoading());

    try {
      final bookings = await _repository.getCustomerBookings(
        customerId: trimmedCustomerId,
      );

      emit(BookingLoaded(bookings));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> loadBarberBookings({required String barberId}) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const BookingError('Barber ID cannot be empty.'));
      return;
    }

    emit(const BookingLoading());

    try {
      final bookings = await _repository.getBarberBookings(
        barberId: trimmedBarberId,
      );

      emit(BookingLoaded(bookings));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> loadBarberBookingsForDate({
    required String barberId,
    required DateTime date,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const BookingError('Barber ID cannot be empty.'));
      return;
    }

    emit(const BookingLoading());

    try {
      final bookings = await _repository.getBarberBookingsForDate(
        barberId: trimmedBarberId,
        date: date,
      );

      emit(BookingLoaded(bookings));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> loadAvailableSlots({
    required String barberId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    final trimmedBarberId = barberId.trim();

    if (trimmedBarberId.isEmpty) {
      emit(const BookingError('Barber ID cannot be empty.'));
      return;
    }

    if (serviceDurationMinutes <= 0) {
      emit(const BookingError('Service duration must be greater than zero.'));
      return;
    }

    if (serviceDurationMinutes % 5 != 0) {
      emit(
        const BookingError('Service duration must be a multiple of 5 minutes.'),
      );
      return;
    }

    emit(const AvailabilityLoading());

    try {
      final slots = await _getAvailableSlots(
        barberId: trimmedBarberId,
        date: date,
        serviceDurationMinutes: serviceDurationMinutes,
      );

      emit(
        AvailabilityLoaded(
          date: DateTime(date.year, date.month, date.day),
          barberId: trimmedBarberId,
          serviceDurationMinutes: serviceDurationMinutes,
          slots: slots,
        ),
      );
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> loadBooking({required String bookingId}) async {
    final trimmedBookingId = bookingId.trim();

    if (trimmedBookingId.isEmpty) {
      emit(const BookingError('Booking ID cannot be empty.'));
      return;
    }

    emit(const BookingLoading());

    try {
      final booking = await _repository.getBooking(bookingId: trimmedBookingId);

      if (booking == null) {
        emit(const BookingError('Booking not found.'));
        return;
      }

      emit(BookingLoaded([booking]));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> createBooking({required Booking booking}) async {
    final validationError = _validateBooking(booking);

    if (validationError != null) {
      emit(BookingError(validationError));
      return;
    }

    emit(const BookingCreating());

    try {
      final createdBooking = await _createBooking(booking: booking);

      emit(BookingCreated(createdBooking));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  Future<void> cancelBooking({required String bookingId}) async {
    final trimmedBookingId = bookingId.trim();

    if (trimmedBookingId.isEmpty) {
      emit(const BookingError('Booking ID cannot be empty.'));
      return;
    }

    emit(BookingCancelling(trimmedBookingId));

    try {
      await _repository.cancelBooking(bookingId: trimmedBookingId);

      emit(BookingCancelled(trimmedBookingId));
    } catch (e) {
      emit(BookingError(_mapError(e)));
    }
  }

  String? _validateBooking(Booking booking) {
    if (booking.customerId.trim().isEmpty) {
      return 'Customer ID cannot be empty.';
    }

    if (booking.shopId.trim().isEmpty) {
      return 'Shop ID cannot be empty.';
    }

    if (booking.barberId.trim().isEmpty) {
      return 'Barber ID cannot be empty.';
    }

    if (booking.serviceId.trim().isEmpty) {
      return 'Service ID cannot be empty.';
    }

    if (booking.serviceName.trim().isEmpty) {
      return 'Service name cannot be empty.';
    }

    if (booking.customerName.trim().isEmpty) {
      return 'Customer name cannot be empty.';
    }

    if (booking.barberName.trim().isEmpty) {
      return 'Barber name cannot be empty.';
    }

    if (booking.serviceDurationMinutes <= 0) {
      return 'Service duration must be greater than zero.';
    }

    if (booking.serviceDurationMinutes % 5 != 0) {
      return 'Service duration must be a multiple of 5 minutes.';
    }

    if (booking.servicePrice < 0) {
      return 'Service price cannot be negative.';
    }

    if (!_isValidTime(booking.startTime)) {
      return 'Invalid booking start time.';
    }

    if (!_isValidTime(booking.endTime)) {
      return 'Invalid booking end time.';
    }

    final startMinutes = _timeToMinutes(booking.startTime);

    final endMinutes = _timeToMinutes(booking.endTime);

    if (startMinutes % 5 != 0) {
      return 'Booking start time must be on a 5-minute interval.';
    }

    if (endMinutes <= startMinutes) {
      return 'Booking end time must be after start time.';
    }

    final actualDuration = endMinutes - startMinutes;

    if (actualDuration != booking.serviceDurationMinutes) {
      return 'Booking duration does not match service duration.';
    }

    return null;
  }

  bool _isValidTime(String value) {
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      throw ArgumentError('Invalid time format: $value');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Invalid time value: $value');
    }

    return (hour * 60) + minute;
  }

  String _mapError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid booking data.';
    }

    if (error is StateError) {
      return error.message;
    }

    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }

    if (message.contains('FAILED_PRECONDITION')) {
      return 'A required Firestore index may be missing.';
    }

    if (message.toLowerCase().contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }
}

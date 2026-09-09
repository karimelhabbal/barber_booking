import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import 'get_available_slots.dart';

class CreateBooking {
  const CreateBooking({
    required this._bookingRepository,
    required this._getAvailableSlots,
  });

  final BookingRepository _bookingRepository;
  final GetAvailableSlots _getAvailableSlots;

  Future<Booking> call({required Booking booking}) async {
    _validateBooking(booking);

    final normalizedDate = DateTime(
      booking.bookingDate.year,
      booking.bookingDate.month,
      booking.bookingDate.day,
    );

    final selectedStart = _combineDateAndTime(
      normalizedDate,
      booking.startTime,
    );

    final selectedEnd = _combineDateAndTime(normalizedDate, booking.endTime);

    final availableSlots = await _getAvailableSlots(
      barberId: booking.barberId,
      date: normalizedDate,
      serviceDurationMinutes: booking.serviceDurationMinutes,
    );

    final selectedSlotIsAvailable = availableSlots.any(
      (slot) =>
          _sameDateTime(slot.start, selectedStart) &&
          _sameDateTime(slot.end, selectedEnd),
    );

    if (!selectedSlotIsAvailable) {
      throw StateError('The selected time slot is no longer available.');
    }

    return _bookingRepository.createBooking(
      booking: booking.copyWith(bookingDate: normalizedDate),
    );
  }

  void _validateBooking(Booking booking) {
    if (booking.customerId.trim().isEmpty) {
      throw ArgumentError('Customer ID cannot be empty.');
    }

    if (booking.shopId.trim().isEmpty) {
      throw ArgumentError('Shop ID cannot be empty.');
    }

    if (booking.barberId.trim().isEmpty) {
      throw ArgumentError('Barber ID cannot be empty.');
    }

    if (booking.serviceId.trim().isEmpty) {
      throw ArgumentError('Service ID cannot be empty.');
    }

    if (booking.serviceName.trim().isEmpty) {
      throw ArgumentError('Service name cannot be empty.');
    }

    if (booking.customerName.trim().isEmpty) {
      throw ArgumentError('Customer name cannot be empty.');
    }

    if (booking.barberName.trim().isEmpty) {
      throw ArgumentError('Barber name cannot be empty.');
    }

    if (booking.serviceDurationMinutes <= 0) {
      throw ArgumentError('Service duration must be greater than zero.');
    }

    if (booking.serviceDurationMinutes % 5 != 0) {
      throw ArgumentError('Service duration must be a multiple of 5 minutes.');
    }

    if (booking.servicePrice < 0) {
      throw ArgumentError('Service price cannot be negative.');
    }

    if (!_isValidTime(booking.startTime)) {
      throw ArgumentError('Invalid booking start time.');
    }

    if (!_isValidTime(booking.endTime)) {
      throw ArgumentError('Invalid booking end time.');
    }

    final startMinutes = _timeToMinutes(booking.startTime);

    final endMinutes = _timeToMinutes(booking.endTime);

    if (startMinutes % 5 != 0) {
      throw ArgumentError('Booking start time must be on a 5-minute interval.');
    }

    if (endMinutes <= startMinutes) {
      throw ArgumentError('Booking end time must be after start time.');
    }

    final actualDuration = endMinutes - startMinutes;

    if (actualDuration != booking.serviceDurationMinutes) {
      throw ArgumentError('Booking duration does not match service duration.');
    }
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

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');

    if (parts.length != 2) {
      throw ArgumentError('Invalid time format: $time');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw ArgumentError('Invalid time value: $time');
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _sameDateTime(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }
}

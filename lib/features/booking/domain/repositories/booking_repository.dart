import '../entities/booking.dart';

abstract interface class BookingRepository {
  Future<List<Booking>> getBarberBookingsForDate({
    required String barberId,
    required DateTime date,
  });

  /// Loads only booked time ranges for availability calculations through
  /// the secure `getBarberAvailability` Cloud Function.
  Future<List<Booking>> getBookedTimeRangesForDate({
    required String barberId,
    required DateTime date,
  });

  Future<List<Booking>> getCustomerBookings({required String customerId});

  Future<List<Booking>> getOwnerBookings({required String shopId});

  Future<List<Booking>> getBarberBookings({required String barberId});

  Future<Booking?> getBooking({required String bookingId});

  Future<Booking> createBooking({required Booking booking});

  Future<void> cancelBooking({required String bookingId});

  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  });
}

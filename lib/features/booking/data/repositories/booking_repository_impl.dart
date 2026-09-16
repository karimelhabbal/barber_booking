import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({required this._remoteDataSource});

  final BookingRemoteDataSource _remoteDataSource;

  @override
  Future<List<Booking>> getBarberBookingsForDate({
    required String barberId,
    required DateTime date,
  }) {
    return _remoteDataSource.getBarberBookingsForDate(
      barberId: barberId,
      date: date,
    );
  }

  @override
  Future<List<Booking>> getCustomerBookings({required String customerId}) {
    return _remoteDataSource.getCustomerBookings(customerId: customerId);
  }

  @override
  Future<List<Booking>> getOwnerBookings({required String shopId}) {
    return _remoteDataSource.getOwnerBookings(shopId: shopId);
  }

  @override
  Future<List<Booking>> getBarberBookings({required String barberId}) {
    return _remoteDataSource.getBarberBookings(barberId: barberId);
  }

  @override
  Future<Booking?> getBooking({required String bookingId}) {
    return _remoteDataSource.getBooking(bookingId: bookingId);
  }

  @override
  Future<Booking> createBooking({required Booking booking}) {
    return _remoteDataSource.createBooking(
      booking: BookingModel.fromEntity(booking),
    );
  }

  @override
  Future<void> cancelBooking({required String bookingId}) {
    return _remoteDataSource.cancelBooking(bookingId: bookingId);
  }

  @override
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) {
    return _remoteDataSource.updateBookingStatus(
      bookingId: bookingId,
      status: status,
    );
  }
}

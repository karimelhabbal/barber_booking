import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

abstract interface class BookingRemoteDataSource {
  Future<List<BookingModel>> getBarberBookingsForDate({required String barberId, required DateTime date});
  Future<List<BookingModel>> getBookedTimeRangesForDate({required String barberId, required DateTime date});
  Future<List<BookingModel>> getCustomerBookings({required String customerId});
  Future<List<BookingModel>> getOwnerBookings({required String shopId});
  Future<List<BookingModel>> getBarberBookings({required String barberId});
  Future<BookingModel?> getBooking({required String bookingId});
  Future<BookingModel> createBooking({required BookingModel booking});
  Future<void> cancelBooking({required String bookingId, required CancelledBy cancelledBy});
  Future<void> updateBookingStatus({required String bookingId, required BookingStatus status, CancelledBy? cancelledBy});
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl({required this._client});
  final SupabaseClient _client;

  @override
  Future<List<BookingModel>> getBarberBookingsForDate({required String barberId, required DateTime date}) async {
    _requireId(barberId, 'Barber');
    final rows = await _client.from('bookings').select().eq('barber_id', barberId.trim())
        .eq('booking_date', _dateString(date)).neq('status', 'cancelled');
    return rows.map(BookingModel.fromJson).toList();
  }

  @override
  Future<List<BookingModel>> getBookedTimeRangesForDate({required String barberId, required DateTime date}) async {
    _requireId(barberId, 'Barber');
    final rows = await _client.from('booking_locks').select('barber_id, booking_date, start_time, end_time')
        .eq('barber_id', barberId.trim()).eq('booking_date', _dateString(date));
    final day = DateTime(date.year, date.month, date.day);
    return rows.map((row) => BookingModel(
      id: '', customerId: '', shopId: '', barberId: row['barber_id'] as String,
      serviceId: '', bookingDate: day,
      startTime: _timeText(row['start_time']), endTime: _timeText(row['end_time']),
      status: BookingStatus.confirmed, serviceName: '', serviceDurationMinutes: 0,
      servicePrice: 0, customerName: '', barberName: '', createdAt: day, updatedAt: day,
    )).toList();
  }

  @override
  Future<List<BookingModel>> getCustomerBookings({required String customerId}) async {
    _requireId(customerId, 'Customer');
    final rows = await _client.from('bookings').select().eq('customer_id', customerId.trim())
        .order('booking_date', ascending: false);
    return rows.map(BookingModel.fromJson).toList();
  }

  @override
  Future<List<BookingModel>> getOwnerBookings({required String shopId}) async {
    _requireId(shopId, 'Barber shop');
    final rows = await _client.from('bookings').select().eq('shop_id', shopId.trim())
        .order('booking_date', ascending: false);
    return rows.map(BookingModel.fromJson).toList();
  }

  @override
  Future<List<BookingModel>> getBarberBookings({required String barberId}) async {
    _requireId(barberId, 'Barber');
    final rows = await _client.from('bookings').select().eq('barber_id', barberId.trim())
        .order('booking_date', ascending: false);
    return rows.map(BookingModel.fromJson).toList();
  }

  @override
  Future<BookingModel?> getBooking({required String bookingId}) async {
    _requireId(bookingId, 'Booking');
    final row = await _client.from('bookings').select().eq('id', bookingId.trim()).maybeSingle();
    return row == null ? null : BookingModel.fromJson(row);
  }

  @override
  Future<BookingModel> createBooking({required BookingModel booking}) async {
    _validateBooking(booking);
    final response = await _client.rpc('create_booking_with_locks', params: {
      'p_shop_id': booking.shopId.trim(),
      'p_barber_id': booking.barberId.trim(),
      'p_service_id': booking.serviceId.trim(),
      'p_booking_date': _dateString(booking.bookingDate),
      'p_start_time': booking.startTime,
      'p_end_time': booking.endTime,
      'p_service_name': booking.serviceName.trim(),
      'p_service_duration_minutes': booking.serviceDurationMinutes,
      'p_service_price': booking.servicePrice,
      'p_customer_name': booking.customerName.trim(),
      'p_barber_name': booking.barberName.trim(),
    });
    return BookingModel.fromJson(_singleRow(response));
  }

  @override
  Future<void> cancelBooking({required String bookingId, required CancelledBy cancelledBy}) async {
    _requireId(bookingId, 'Booking');
    await _client.rpc('cancel_booking_and_release_locks', params: {
      'p_booking_id': bookingId.trim(),
      'p_cancelled_by': BookingModel.cancelledByToFirestore(cancelledBy),
    });
  }

  @override
  Future<void> updateBookingStatus({required String bookingId, required BookingStatus status, CancelledBy? cancelledBy}) async {
    _requireId(bookingId, 'Booking');
    await _client.rpc('update_booking_status', params: {
      'p_booking_id': bookingId.trim(),
      'p_status': BookingModel.statusToFirestore(status),
    });
  }

  static Map<String, dynamic> _singleRow(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw StateError('Supabase booking operation returned no booking row.');
  }

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _timeText(Object? value) => value is String ? value.substring(0, 5) : '$value'.substring(0, 5);

  static void _requireId(String id, String label) {
    if (id.trim().isEmpty) throw ArgumentError('$label ID cannot be empty.');
  }

  void _validateBooking(BookingModel booking) {
    for (final entry in <String, String>{
      'Customer': booking.customerId, 'Barber shop': booking.shopId,
      'Barber': booking.barberId, 'Service': booking.serviceId,
      'Service name': booking.serviceName, 'Customer name': booking.customerName,
      'Barber name': booking.barberName,
    }.entries) {
      if (entry.value.trim().isEmpty) throw ArgumentError('${entry.key} cannot be empty.');
    }
    if (booking.serviceDurationMinutes <= 0 || booking.serviceDurationMinutes % 5 != 0) {
      throw ArgumentError('Service duration must be a positive multiple of 5 minutes.');
    }
    if (booking.servicePrice < 0) throw ArgumentError('Service price cannot be negative.');
    if (!_validTime(booking.startTime) || !_validTime(booking.endTime)) throw ArgumentError('Invalid booking time.');
    final start = _minutes(booking.startTime);
    final end = _minutes(booking.endTime);
    if (start % 5 != 0) throw ArgumentError('Booking start time must be on a 5-minute interval.');
    if (end <= start) throw ArgumentError('Booking end time must be after start time.');
    if (end - start != booking.serviceDurationMinutes) throw ArgumentError('Booking duration does not match service duration.');
  }

  bool _validTime(String value) => RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value);
  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

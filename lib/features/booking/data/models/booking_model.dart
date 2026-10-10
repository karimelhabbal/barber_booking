import '../../domain/entities/booking.dart';

export '../../domain/entities/booking.dart' show CancelledBy;

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.customerId,
    required super.shopId,
    required super.barberId,
    required super.serviceId,
    required super.bookingDate,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.serviceName,
    required super.serviceDurationMinutes,
    required super.servicePrice,
    required super.customerName,
    required super.barberName,
    required super.createdAt,
    required super.updatedAt,
    super.cancelledBy,
  });

  factory BookingModel.fromJson(Map<String, dynamic> data) {
    return BookingModel(
      id: data['id'] as String,
      customerId: data['customer_id'] as String? ?? '',
      shopId: data['shop_id'] as String? ?? '',
      barberId: data['barber_id'] as String? ?? '',
      serviceId: data['service_id'] as String? ?? '',
      bookingDate: _readDate(data['booking_date']),
      startTime: data['start_time'] as String? ?? '',
      endTime: data['end_time'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      serviceName: data['service_name'] as String? ?? '',
      serviceDurationMinutes: (data['service_duration_minutes'] as num?)?.toInt() ?? 0,
      servicePrice: (data['service_price'] as num?)?.toDouble() ?? 0,
      customerName: data['customer_name'] as String? ?? '',
      barberName: data['barber_name'] as String? ?? '',
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      cancelledBy: _parseCancelledBy(data['cancelled_by']),
    );
  }

  factory BookingModel.fromEntity(Booking booking) {
    return BookingModel(
      id: booking.id,
      customerId: booking.customerId,
      shopId: booking.shopId,
      barberId: booking.barberId,
      serviceId: booking.serviceId,
      bookingDate: booking.bookingDate,
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: booking.status,
      serviceName: booking.serviceName,
      serviceDurationMinutes: booking.serviceDurationMinutes,
      servicePrice: booking.servicePrice,
      customerName: booking.customerName,
      barberName: booking.barberName,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
      cancelledBy: booking.cancelledBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'shop_id': shopId,
      'barber_id': barberId,
      'service_id': serviceId,
      'booking_date': _dateString(bookingDate),
      'start_time': startTime,
      'end_time': endTime,
      'status': statusToFirestore(status),
      'cancelled_by': cancelledByToFirestore(cancelledBy),
      'service_name': serviceName,
      'service_duration_minutes': serviceDurationMinutes,
      'service_price': servicePrice,
      'customer_name': customerName,
      'barber_name': barberName,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is String) {
      final parts = value.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }
    if (value is DateTime) return DateTime(value.year, value.month, value.day);
    throw StateError('Booking date must be a PostgreSQL date, received $value.');
  }

  static String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static BookingStatus _parseStatus(String? value) {
    switch (value) {
      case 'pending':
        return BookingStatus.pending;

      case 'confirmed':
        return BookingStatus.confirmed;

      case 'completed':
        return BookingStatus.completed;

      case 'cancelled':
        return BookingStatus.cancelled;

      case 'noShow':
        return BookingStatus.noShow;

      default:
        throw StateError('Unknown booking status: $value');
    }
  }

  static String statusToFirestore(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';

      case BookingStatus.confirmed:
        return 'confirmed';

      case BookingStatus.completed:
        return 'completed';

      case BookingStatus.cancelled:
        return 'cancelled';

      case BookingStatus.noShow:
        return 'noShow';
    }
  }

  static CancelledBy? _parseCancelledBy(Object? value) {
    switch (value) {
      case 'customer':
        return CancelledBy.customer;
      case 'barber':
        return CancelledBy.barber;
      case 'owner':
        return CancelledBy.owner;
      default:
        // Legacy documents predate the actor field.
        return null;
    }
  }

  static String? cancelledByToFirestore(CancelledBy? value) {
    switch (value) {
      case CancelledBy.customer:
        return 'customer';
      case CancelledBy.barber:
        return 'barber';
      case CancelledBy.owner:
        return 'owner';
      case null:
        return null;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory BookingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Booking document ${document.id} does not exist.');
    }

    return BookingModel(
      id: document.id,
      customerId: data['customerId'] as String? ?? '',
      shopId: data['shopId'] as String? ?? '',
      barberId: data['barberId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      bookingDate: _readTimestamp(
        data['bookingDate'],
        fieldName: 'bookingDate',
      ),
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      serviceName: data['serviceName'] as String? ?? '',
      serviceDurationMinutes: data['serviceDurationMinutes'] as int? ?? 0,
      servicePrice: (data['servicePrice'] as num?)?.toDouble() ?? 0,
      customerName: data['customerName'] as String? ?? '',
      barberName: data['barberName'] as String? ?? '',
      createdAt: _readTimestamp(data['createdAt'], fieldName: 'createdAt'),
      updatedAt: _readTimestamp(data['updatedAt'], fieldName: 'updatedAt'),
      cancelledBy: _parseCancelledBy(data['cancelledBy']),
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

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'barberId': barberId,
      'serviceId': serviceId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'startTime': startTime,
      'endTime': endTime,
      'status': statusToFirestore(status),
      'cancelledBy': cancelledByToFirestore(cancelledBy),
      'serviceName': serviceName,
      'serviceDurationMinutes': serviceDurationMinutes,
      'servicePrice': servicePrice,
      'customerName': customerName,
      'barberName': barberName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _readTimestamp(Object? value, {required String fieldName}) {
    if (value is Timestamp) {
      return value.toDate();
    }

    throw StateError('Booking field $fieldName must be a Firestore Timestamp.');
  }

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

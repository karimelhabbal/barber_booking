import 'package:equatable/equatable.dart';

enum BookingStatus { pending, confirmed, completed, cancelled, noShow }

/// Who performed a booking cancellation, when known.
enum CancelledBy { customer, barber, owner }

class Booking extends Equatable {
  final String id;
  final String customerId;
  final String shopId;
  final String barberId;
  final String serviceId;

  final DateTime bookingDate;
  final String startTime;
  final String endTime;

  final BookingStatus status;

  /// Set only when [status] is cancelled.
  final CancelledBy? cancelledBy;

  final String serviceName;
  final int serviceDurationMinutes;
  final double servicePrice;

  final String customerName;
  final String barberName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.shopId,
    required this.barberId,
    required this.serviceId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.serviceName,
    required this.serviceDurationMinutes,
    required this.servicePrice,
    required this.customerName,
    required this.barberName,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledBy,
  });

  Booking copyWith({
    String? id,
    String? customerId,
    String? shopId,
    String? barberId,
    String? serviceId,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    BookingStatus? status,
    String? serviceName,
    int? serviceDurationMinutes,
    double? servicePrice,
    String? customerName,
    String? barberName,
    DateTime? createdAt,
    DateTime? updatedAt,
    CancelledBy? cancelledBy,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      barberId: barberId ?? this.barberId,
      serviceId: serviceId ?? this.serviceId,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      serviceName: serviceName ?? this.serviceName,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      servicePrice: servicePrice ?? this.servicePrice,
      customerName: customerName ?? this.customerName,
      barberName: barberName ?? this.barberName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    shopId,
    barberId,
    serviceId,
    bookingDate,
    startTime,
    endTime,
    status,
    cancelledBy,
    serviceName,
    serviceDurationMinutes,
    servicePrice,
    customerName,
    barberName,
    createdAt,
    updatedAt,
  ];
}

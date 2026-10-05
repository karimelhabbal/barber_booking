import 'package:equatable/equatable.dart';

import 'payment_enums.dart';

/// Amounts are INTEGER PIASTERS (100 = 1.00 EGP).
class BookingPayment extends Equatable {
  const BookingPayment({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.status,
    required this.grossAmount,
    required this.commissionAmount,
    required this.ownerNetAmount,
    required this.refundedAmount,
    required this.createdAt,
    this.paidAt,
    this.failureReason,
  });

  final String id;
  final String bookingId;
  final PaymentMethod method;
  final BookingPaymentStatus status;
  final int grossAmount;
  final int commissionAmount;
  final int ownerNetAmount;
  final int refundedAmount;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? failureReason;

  bool get isPaidOnline =>
      status == BookingPaymentStatus.paid ||
      status == BookingPaymentStatus.partiallyRefunded ||
      status == BookingPaymentStatus.refunded;
  bool get isCashRecorded =>
      status == BookingPaymentStatus.cashPending || status == BookingPaymentStatus.cashCollected;
  bool get isOpen => status == BookingPaymentStatus.pending;
  bool get isTerminalFailure =>
      status == BookingPaymentStatus.failed ||
      status == BookingPaymentStatus.expired ||
      status == BookingPaymentStatus.cancelled;

  @override
  List<Object?> get props =>
      [id, bookingId, method, status, grossAmount, commissionAmount, ownerNetAmount, refundedAmount, createdAt, paidAt, failureReason];
}

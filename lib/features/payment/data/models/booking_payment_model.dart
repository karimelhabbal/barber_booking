import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_payment.dart';
import '../../domain/entities/payment_enums.dart';
import 'firestore_parsing.dart';

class BookingPaymentModel {
  static BookingPayment fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const <String, dynamic>{};
    return BookingPayment(
      id: snap.id,
      bookingId: (d['bookingId'] as String?) ?? '',
      method: d['method'] == 'cash' ? PaymentMethod.cash : PaymentMethod.online,
      status: parseBookingPaymentStatus(d['status'] as String?),
      grossAmount: readInt(d['grossAmount']),
      commissionAmount: readInt(d['commissionAmount']),
      ownerNetAmount: readInt(d['ownerNetAmount']),
      refundedAmount: readInt(d['refundedAmount']),
      createdAt: readDateOr(d['createdAt'], DateTime.fromMillisecondsSinceEpoch(0)),
      paidAt: readDate(d['paidAt']),
      failureReason: d['failureReason'] as String?,
    );
  }
}

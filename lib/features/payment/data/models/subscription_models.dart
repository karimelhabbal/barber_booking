import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/subscription.dart';
import 'firestore_parsing.dart';

class SubscriptionModels {
  static SubscriptionPlan plan(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const <String, dynamic>{};
    return SubscriptionPlan(
      id: snap.id,
      name: (d['name'] as String?) ?? '',
      interval: parseInterval(d['interval'] as String?),
      price: readInt(d['price']),
      sortOrder: readInt(d['sortOrder']),
    );
  }

  static OwnerSubscription ownerSubscription(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const <String, dynamic>{};
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return OwnerSubscription(
      ownerId: snap.id,
      planId: (d['planId'] as String?) ?? '',
      interval: parseInterval(d['interval'] as String?),
      status: d['status'] == 'active' ? SubscriptionStatus.active : SubscriptionStatus.expired,
      currentPeriodStart: readDateOr(d['currentPeriodStart'], epoch),
      currentPeriodEnd: readDateOr(d['currentPeriodEnd'], epoch),
    );
  }

  static SubscriptionPayment payment(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const <String, dynamic>{};
    return SubscriptionPayment(
      id: snap.id,
      planId: (d['planId'] as String?) ?? '',
      amount: readInt(d['amountPiasters'] ?? d['amount']),
      status: parseSubscriptionPaymentStatus(d['status'] as String?),
    );
  }
}

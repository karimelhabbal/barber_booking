import 'package:equatable/equatable.dart';

import 'payment_enums.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.interval,
    required this.price,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final SubscriptionInterval interval;
  final int price; // piasters
  final int sortOrder;

  @override
  List<Object?> get props => [id, name, interval, price, sortOrder];
}

class OwnerSubscription extends Equatable {
  const OwnerSubscription({
    required this.ownerId,
    required this.planId,
    required this.interval,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
  });

  final String ownerId;
  final String planId;
  final SubscriptionInterval interval;
  final SubscriptionStatus status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;

  /// Display helper only. The backend (scheduled job) is authoritative for expiry.
  bool isActiveAt(DateTime now) => status == SubscriptionStatus.active && currentPeriodEnd.isAfter(now);

  @override
  List<Object?> get props => [ownerId, planId, interval, status, currentPeriodStart, currentPeriodEnd];
}

class SubscriptionPayment extends Equatable {
  const SubscriptionPayment({
    required this.id,
    required this.planId,
    required this.amount,
    required this.status,
  });

  final String id;
  final String planId;
  final int amount;
  final SubscriptionPaymentStatus status;

  @override
  List<Object?> get props => [id, planId, amount, status];
}

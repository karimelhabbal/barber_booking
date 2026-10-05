import 'package:equatable/equatable.dart';

import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/failures/payment_failure.dart';

enum SubscriptionFlow {
  initial,
  loading,
  ready,
  submitting,
  checkoutReady,
  tracking,
  activated,
  failed,
}

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.flow = SubscriptionFlow.initial,
    this.plans = const [],
    this.billingEmail = '',
    this.subscription,
    this.session,
    this.failure,
    this.verifyingTooLong = false,
  });

  final SubscriptionFlow flow;
  final List<SubscriptionPlan> plans;
  final String billingEmail;
  final OwnerSubscription? subscription;
  final CheckoutSession? session;
  final PaymentFailure? failure;
  final bool verifyingTooLong;

  SubscriptionState copyWith({
    SubscriptionFlow? flow,
    List<SubscriptionPlan>? plans,
    String? billingEmail,
    OwnerSubscription? subscription,
    CheckoutSession? session,
    PaymentFailure? failure,
    bool? verifyingTooLong,
    bool clearFailure = false,
    bool clearSession = false,
  }) {
    return SubscriptionState(
      flow: flow ?? this.flow,
      plans: plans ?? this.plans,
      billingEmail: billingEmail ?? this.billingEmail,
      subscription: subscription ?? this.subscription,
      session: clearSession ? null : (session ?? this.session),
      failure: clearFailure ? null : (failure ?? this.failure),
      verifyingTooLong: verifyingTooLong ?? this.verifyingTooLong,
    );
  }

  @override
  List<Object?> get props => [
    flow,
    plans,
    billingEmail,
    subscription,
    session,
    failure,
    verifyingTooLong,
  ];
}

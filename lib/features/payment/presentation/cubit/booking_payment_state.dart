import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_payment.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/payment_enums.dart';
import '../../domain/failures/payment_failure.dart';

enum BookingPaymentFlow {
  initial,
  loading,
  ready,
  submitting,
  checkoutReady,
  tracking,
  succeeded,
  cashRecorded,
  failed,
}

class BookingPaymentState extends Equatable {
  const BookingPaymentState({
    this.flow = BookingPaymentFlow.initial,
    this.options,
    this.selected,
    this.billingEmail = '',
    this.session,
    this.payment,
    this.failure,
    this.verifyingTooLong = false,
  });

  final BookingPaymentFlow flow;
  final ShopPaymentOptions? options;
  final PaymentMethod? selected;
  final String billingEmail;
  final CheckoutSession? session;
  final BookingPayment? payment;
  final PaymentFailure? failure;
  final bool verifyingTooLong;

  BookingPaymentState copyWith({
    BookingPaymentFlow? flow,
    ShopPaymentOptions? options,
    PaymentMethod? selected,
    String? billingEmail,
    CheckoutSession? session,
    BookingPayment? payment,
    PaymentFailure? failure,
    bool? verifyingTooLong,
    bool clearFailure = false,
    bool clearSession = false,
  }) {
    return BookingPaymentState(
      flow: flow ?? this.flow,
      options: options ?? this.options,
      selected: selected ?? this.selected,
      billingEmail: billingEmail ?? this.billingEmail,
      session: clearSession ? null : (session ?? this.session),
      payment: payment ?? this.payment,
      failure: clearFailure ? null : (failure ?? this.failure),
      verifyingTooLong: verifyingTooLong ?? this.verifyingTooLong,
    );
  }

  @override
  List<Object?> get props => [
    flow,
    options,
    selected,
    billingEmail,
    session,
    payment,
    failure,
    verifyingTooLong,
  ];
}

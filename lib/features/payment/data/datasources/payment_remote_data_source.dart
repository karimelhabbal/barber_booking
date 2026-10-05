import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/booking_payment.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/payout_destination.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/failures/payment_failure.dart';
import '../models/booking_payment_model.dart';
import '../models/payout_destination_model.dart';
import '../models/subscription_models.dart';

/// Talks to Cloud Functions (all financial writes) and Firestore (read-only streams).
/// To move to Supabase: re-implement this class only; domain and presentation stay untouched.
class PaymentRemoteDataSource {
  PaymentRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) : _db = firestore,
       _fn = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  // ---- callables ----
  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _fn.httpsCallable(name).call<Object?>(data);
      final raw = res.data;
      return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw PaymentFailure(_mapCode(e.code), reason: e.message ?? '');
    }
  }

  PaymentFailureCode _mapCode(String code) {
    switch (code) {
      case 'unauthenticated':
        return PaymentFailureCode.unauthenticated;
      case 'permission-denied':
        return PaymentFailureCode.permissionDenied;
      case 'not-found':
        return PaymentFailureCode.notFound;
      case 'invalid-argument':
        return PaymentFailureCode.invalidArgument;
      case 'failed-precondition':
        return PaymentFailureCode.failedPrecondition;
      case 'already-exists':
        return PaymentFailureCode.alreadyExists;
      case 'unavailable':
      case 'deadline-exceeded':
        return PaymentFailureCode.unavailable;
      default:
        return PaymentFailureCode.unknown;
    }
  }

  Future<CheckoutSession> createBookingPayment({
    required String bookingId,
    required PaymentMethod method,
    required String billingEmail,
  }) async {
    final r = await _call('createBookingPayment', {
      'bookingId': bookingId,
      'method': method.wire,
      if (billingEmail.trim().isNotEmpty) 'billingEmail': billingEmail.trim(),
    });
    return CheckoutSession(
      paymentId: r['paymentId'] as String,
      checkoutUrl: r['checkoutUrl'] as String?,
    );
  }

  Future<void> refreshPaymentStatus(String paymentId) async {
    await _call('refreshPaymentStatus', {'paymentId': paymentId});
  }

  Future<CheckoutSession> startSubscriptionCheckout(
    String planId,
    String billingEmail,
  ) async {
    final r = await _call('createSubscriptionCheckout', {
      'planId': planId,
      'billingEmail': billingEmail.trim(),
    });
    return CheckoutSession(
      paymentId: r['paymentId'] as String,
      checkoutUrl: r['checkoutUrl'] as String?,
    );
  }

  Future<void> savePayoutDestination(PayoutDestination d) async {
    await _call('setPayoutDestination', {
      'type': d.type == PayoutDestinationType.iban ? 'iban' : 'wallet',
      'accountHolderName': d.accountHolderName,
      if (d.walletMsisdn != null) 'walletMsisdn': d.walletMsisdn,
      if (d.iban != null) 'iban': d.iban,
    });
  }

  // ---- read-only Firestore ----
  Future<ShopPaymentOptions> getShopPaymentOptions(String shopId) async {
    final d = await _call('getShopPaymentOptions', {'shopId': shopId});
    return ShopPaymentOptions(
      onlineEnabled: d['onlineEnabled'] == true,
      cashEnabled: d['cashEnabled'] == true,
    );
  }

  Stream<BookingPayment?> watchPayment(String paymentId) => _db
      .collection('bookingPayments')
      .doc(paymentId)
      .snapshots()
      .map((s) => s.exists ? BookingPaymentModel.fromSnapshot(s) : null);

  Future<List<SubscriptionPlan>> getActivePlans() async {
    final q = await _db
        .collection('subscriptionPlans')
        .where('active', isEqualTo: true)
        .get();
    final plans = q.docs.map(SubscriptionModels.plan).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return plans;
  }

  Stream<OwnerSubscription?> watchSubscription(String ownerId) => _db
      .collection('ownerSubscriptions')
      .doc(ownerId)
      .snapshots()
      .map((s) => s.exists ? SubscriptionModels.ownerSubscription(s) : null);

  Stream<SubscriptionPayment?> watchSubscriptionPayment(String paymentId) => _db
      .collection('subscriptionPayments')
      .doc(paymentId)
      .snapshots()
      .map((s) => s.exists ? SubscriptionModels.payment(s) : null);

  Stream<PayoutDestination?> watchPayoutDestination(String ownerId) => _db
      .collection('payoutDestinations')
      .doc(ownerId)
      .snapshots()
      .map((s) => s.exists ? PayoutDestinationModel.fromSnapshot(s) : null);
}

import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Future<List<SubscriptionPlan>> getActivePlans() async {
    try {
      return await _remote.getActivePlans();
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unavailable);
    }
  }

  @override
  Stream<OwnerSubscription?> watchSubscription(String ownerId) =>
      _remote.watchSubscription(ownerId);

  @override
  Future<CheckoutSession> startCheckout(
    String planId,
    String billingEmail,
  ) async {
    try {
      return await _remote.startSubscriptionCheckout(planId, billingEmail);
    } on PaymentFailure {
      rethrow;
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unknown);
    }
  }

  @override
  Stream<SubscriptionPayment?> watchSubscriptionPayment(String paymentId) =>
      _remote.watchSubscriptionPayment(paymentId);
}

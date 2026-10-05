import '../entities/checkout_session.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getActivePlans();

  Stream<OwnerSubscription?> watchSubscription(String ownerId);

  /// Throws [PaymentFailure]. Returns the hosted checkout URL (never a payment result).
  Future<CheckoutSession> startCheckout(String planId, String billingEmail);

  Stream<SubscriptionPayment?> watchSubscriptionPayment(String paymentId);
}

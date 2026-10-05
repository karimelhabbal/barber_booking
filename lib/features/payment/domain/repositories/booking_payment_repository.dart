import '../entities/booking_payment.dart';
import '../entities/checkout_session.dart';
import '../entities/payment_enums.dart';

abstract class BookingPaymentRepository {
  /// Throws [PaymentFailure].
  Future<ShopPaymentOptions> getShopPaymentOptions(String shopId);

  /// Throws [PaymentFailure]. The backend validates ownership, price, method and commission.
  Future<CheckoutSession> createBookingPayment({
    required String bookingId,
    required PaymentMethod method,
    required String billingEmail,
  });

  /// Emits null if the document does not exist. Status is server-authoritative.
  Stream<BookingPayment?> watchPayment(String paymentId);

  /// Asks the backend to re-verify with the provider (it rate-limits). Never decides status itself.
  Future<void> refreshPaymentStatus(String paymentId);
}

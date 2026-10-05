import '../../domain/entities/booking_payment.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/payment_enums.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/booking_payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class BookingPaymentRepositoryImpl implements BookingPaymentRepository {
  BookingPaymentRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Future<ShopPaymentOptions> getShopPaymentOptions(String shopId) async {
    try {
      return await _remote.getShopPaymentOptions(shopId);
    } on PaymentFailure {
      rethrow;
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unknown);
    }
  }

  @override
  Future<CheckoutSession> createBookingPayment({
    required String bookingId,
    required PaymentMethod method,
    required String billingEmail,
  }) async {
    try {
      return await _remote.createBookingPayment(
        bookingId: bookingId,
        method: method,
        billingEmail: billingEmail,
      );
    } on PaymentFailure {
      rethrow;
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unknown);
    }
  }

  @override
  Stream<BookingPayment?> watchPayment(String paymentId) =>
      _remote.watchPayment(paymentId);

  @override
  Future<void> refreshPaymentStatus(String paymentId) async {
    try {
      await _remote.refreshPaymentStatus(paymentId);
    } on PaymentFailure {
      rethrow;
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unknown);
    }
  }
}

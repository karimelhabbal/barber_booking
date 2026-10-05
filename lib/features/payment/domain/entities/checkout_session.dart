import 'package:equatable/equatable.dart';

/// Result of asking the backend to start a payment. [checkoutUrl] is null for cash.
class CheckoutSession extends Equatable {
  const CheckoutSession({required this.paymentId, required this.checkoutUrl});

  final String paymentId;
  final String? checkoutUrl;

  @override
  List<Object?> get props => [paymentId, checkoutUrl];
}

class ShopPaymentOptions extends Equatable {
  const ShopPaymentOptions({required this.onlineEnabled, required this.cashEnabled});

  final bool onlineEnabled;
  final bool cashEnabled;

  @override
  List<Object?> get props => [onlineEnabled, cashEnabled];
}

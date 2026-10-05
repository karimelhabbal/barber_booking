import 'package:flutter/widgets.dart';

import 'presentation/pages/booking_payment_page.dart';
import 'presentation/pages/payout_destination_page.dart';
import 'presentation/pages/subscription_page.dart';

/// INTEGRATION POINT — REQUIRES EXISTING PROJECT VALUE: your router.
/// Navigator 1.0:      Navigator.push(context, BookingPaymentPage.route(bookingId: ..., shopId: ..., totalPiasters: ...));
/// go_router / others: build `BookingPaymentPage(...)` directly in your route builder.
/// Optional helper below for `onGenerateRoute` users; the route names are free to change.
class PaymentRoutes {
  const PaymentRoutes._();

  static const bookingPayment = '/payment/booking';
  static const subscription = '/payment/subscription';
  static const payoutDestination = '/payment/payout-destination';

  /// Arguments: Map with the same keys as the page constructors.
  static Route<void>? generate(RouteSettings settings) {
    final args = (settings.arguments as Map<String, Object?>?) ?? const {};
    switch (settings.name) {
      case bookingPayment:
        return BookingPaymentPage.route(
          bookingId: args['bookingId']! as String,
          shopId: args['shopId']! as String,
          totalPiasters: args['totalPiasters']! as int,
        );
      case subscription:
        return SubscriptionPage.route(ownerId: args['ownerId']! as String);
      case payoutDestination:
        return PayoutDestinationPage.route(ownerId: args['ownerId']! as String);
    }
    return null;
  }
}

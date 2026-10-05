enum PaymentMethod { online, cash }

extension PaymentMethodX on PaymentMethod {
  String get wire => this == PaymentMethod.online ? 'online' : 'cash';
}

/// Mirrors backend BookingPaymentStatus. The CLIENT NEVER SETS THIS; it only displays it.
enum BookingPaymentStatus {
  pending,
  paid,
  failed,
  expired,
  cancelled,
  partiallyRefunded,
  refunded,
  cashPending,
  cashCollected,
  unknown,
}

BookingPaymentStatus parseBookingPaymentStatus(String? v) {
  switch (v) {
    case 'pending':
      return BookingPaymentStatus.pending;
    case 'paid':
      return BookingPaymentStatus.paid;
    case 'failed':
      return BookingPaymentStatus.failed;
    case 'expired':
      return BookingPaymentStatus.expired;
    case 'cancelled':
      return BookingPaymentStatus.cancelled;
    case 'partially_refunded':
      return BookingPaymentStatus.partiallyRefunded;
    case 'refunded':
      return BookingPaymentStatus.refunded;
    case 'cash_pending':
      return BookingPaymentStatus.cashPending;
    case 'cash_collected':
      return BookingPaymentStatus.cashCollected;
    default:
      return BookingPaymentStatus.unknown;
  }
}

enum SubscriptionInterval { monthly, yearly }

SubscriptionInterval parseInterval(String? v) =>
    v == 'yearly' ? SubscriptionInterval.yearly : SubscriptionInterval.monthly;

enum SubscriptionStatus { active, expired, none }

enum SubscriptionPaymentStatus { pending, paid, failed, expired, cancelled, unknown }

SubscriptionPaymentStatus parseSubscriptionPaymentStatus(String? v) {
  switch (v) {
    case 'pending':
      return SubscriptionPaymentStatus.pending;
    case 'paid':
      return SubscriptionPaymentStatus.paid;
    case 'failed':
      return SubscriptionPaymentStatus.failed;
    case 'expired':
      return SubscriptionPaymentStatus.expired;
    case 'cancelled':
      return SubscriptionPaymentStatus.cancelled;
    default:
      return SubscriptionPaymentStatus.unknown;
  }
}

enum PayoutDestinationType { wallet, iban }

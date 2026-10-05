/// Domain-level failure. [code] mirrors the backend HttpsError code, [reason] is the backend
/// machine-readable message (e.g. `online_payment_disabled_for_shop`).
enum PaymentFailureCode {
  unauthenticated,
  permissionDenied,
  notFound,
  invalidArgument,
  failedPrecondition,
  alreadyExists,
  unavailable,
  unknown,
}

class PaymentFailure implements Exception {
  const PaymentFailure(this.code, {this.reason = ''});

  final PaymentFailureCode code;
  final String reason;

  @override
  String toString() => 'PaymentFailure($code, $reason)';
}

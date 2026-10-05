import '../entities/payout_destination.dart';

abstract class PayoutDestinationRepository {
  Stream<PayoutDestination?> watch(String ownerId);

  /// Throws [PaymentFailure] (backend validates wallet number / IBAN).
  Future<void> save(PayoutDestination destination);
}

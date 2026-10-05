import '../../domain/entities/payout_destination.dart';
import '../../domain/failures/payment_failure.dart';
import '../../domain/repositories/payout_destination_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PayoutDestinationRepositoryImpl implements PayoutDestinationRepository {
  PayoutDestinationRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Stream<PayoutDestination?> watch(String ownerId) => _remote.watchPayoutDestination(ownerId);

  @override
  Future<void> save(PayoutDestination destination) async {
    try {
      await _remote.savePayoutDestination(destination);
    } on PaymentFailure {
      rethrow;
    } catch (_) {
      throw const PaymentFailure(PaymentFailureCode.unknown);
    }
  }
}

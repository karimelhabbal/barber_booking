import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/payout_destination.dart';

class PayoutDestinationModel {
  static PayoutDestination fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? const <String, dynamic>{};
    return PayoutDestination(
      type: d['type'] == 'iban' ? PayoutDestinationType.iban : PayoutDestinationType.wallet,
      accountHolderName: (d['accountHolderName'] as String?) ?? '',
      walletMsisdn: d['walletMsisdn'] as String?,
      iban: d['iban'] as String?,
    );
  }
}

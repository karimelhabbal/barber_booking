import 'package:equatable/equatable.dart';

import 'payment_enums.dart';

class PayoutDestination extends Equatable {
  const PayoutDestination({
    required this.type,
    required this.accountHolderName,
    this.walletMsisdn,
    this.iban,
  });

  final PayoutDestinationType type;
  final String accountHolderName;
  final String? walletMsisdn;
  final String? iban;

  @override
  List<Object?> get props => [type, accountHolderName, walletMsisdn, iban];
}

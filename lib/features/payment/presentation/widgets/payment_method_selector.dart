import 'package:flutter/material.dart';

import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/payment_enums.dart';
import '../utils/payment_strings.dart';

/// Shows only the methods the shop allows. InstaPay is intentionally NOT offered
/// (not available through the current provider).
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final ShopPaymentOptions options;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!options.onlineEnabled && !options.cashEnabled) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(PaymentStrings.noMethods),
      );
    }
    return Column(
      children: [
        if (options.onlineEnabled)
          _tile(context, PaymentMethod.online, Icons.credit_card, PaymentStrings.online, PaymentStrings.onlineSub),
        if (options.cashEnabled)
          _tile(context, PaymentMethod.cash, Icons.payments_outlined, PaymentStrings.cash, PaymentStrings.cashSub),
      ],
    );
  }

  Widget _tile(BuildContext context, PaymentMethod m, IconData icon, String title, String sub) {
    final isSel = selected == m;
    final color = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSel ? color.primary : color.outlineVariant, width: isSel ? 2 : 1),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(sub),
        trailing: Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off),
        onTap: () => onChanged(m),
      ),
    );
  }
}

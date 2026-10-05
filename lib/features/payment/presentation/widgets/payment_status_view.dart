import 'package:flutter/material.dart';

import '../../domain/failures/payment_failure.dart';
import '../utils/payment_strings.dart';

enum PaymentStatusKind { verifying, success, cash, failure }

class PaymentStatusView extends StatelessWidget {
  const PaymentStatusView({
    super.key,
    required this.kind,
    this.slow = false,
    this.failure,
    this.onRefresh,
    this.onRetry,
    this.onDone,
  });

  final PaymentStatusKind kind;
  final bool slow;
  final PaymentFailure? failure;
  final VoidCallback? onRefresh;
  final VoidCallback? onRetry;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Widget icon;
    late final String title;
    String? subtitle;
    final actions = <Widget>[];

    switch (kind) {
      case PaymentStatusKind.verifying:
        icon = const SizedBox(width: 48, height: 48, child: CircularProgressIndicator());
        title = PaymentStrings.verifying;
        if (slow) {
          subtitle = PaymentStrings.verifyingSlow;
          if (onRefresh != null) {
            actions.add(OutlinedButton(onPressed: onRefresh, child: const Text(PaymentStrings.refresh)));
          }
        }
        break;
      case PaymentStatusKind.success:
        icon = Icon(Icons.check_circle, size: 64, color: scheme.primary);
        title = PaymentStrings.paidOk;
        if (onDone != null) actions.add(FilledButton(onPressed: onDone, child: const Text(PaymentStrings.done)));
        break;
      case PaymentStatusKind.cash:
        icon = Icon(Icons.check_circle_outline, size: 64, color: scheme.primary);
        title = PaymentStrings.cashOk;
        if (onDone != null) actions.add(FilledButton(onPressed: onDone, child: const Text(PaymentStrings.done)));
        break;
      case PaymentStatusKind.failure:
        icon = Icon(Icons.error_outline, size: 64, color: scheme.error);
        title = PaymentStrings.failed;
        if (failure != null) subtitle = PaymentStrings.errorFor(failure!);
        if (onRetry != null) actions.add(FilledButton(onPressed: onRetry, child: const Text(PaymentStrings.tryAgain)));
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center),
            ],
            if (actions.isNotEmpty) ...[const SizedBox(height: 16), ...actions],
          ],
        ),
      ),
    );
  }
}

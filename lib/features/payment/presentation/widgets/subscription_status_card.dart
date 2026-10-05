import 'package:flutter/material.dart';

import '../../domain/entities/subscription.dart';
import '../utils/payment_strings.dart';

class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({super.key, required this.subscription});

  final OwnerSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final s = subscription;
    final active = s != null && s.isActiveAt(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final end = s?.currentPeriodEnd;
    final text = active
        ? '${PaymentStrings.activeUntil} ${end!.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}'
        : (s == null ? PaymentStrings.noSubscription : PaymentStrings.expired);
    return Card(
      color: active ? scheme.primaryContainer : scheme.errorContainer,
      child: ListTile(
        leading: Icon(active ? Icons.verified : Icons.warning_amber_rounded),
        title: Text(text),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/subscription.dart';
import '../cubit/subscription_cubit.dart';
import '../cubit/subscription_state.dart';
import '../utils/money_format.dart';
import '../utils/payment_strings.dart';
import '../widgets/payment_status_view.dart';
import '../widgets/subscription_status_card.dart';
import 'paymob_checkout_page.dart';

/// Owner SaaS subscription screen.
/// INTEGRATION POINT — REQUIRES EXISTING PROJECT VALUE: pass the signed-in owner's uid as [ownerId]
/// (use your own auth state; do not assume a specific auth abstraction).
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key, required this.ownerId});

  final String ownerId;

  static Route<void> route({required String ownerId}) =>
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionPage(ownerId: ownerId),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionCubit>(
      create: (_) => GetIt.I<SubscriptionCubit>()..load(ownerId),
      child: Scaffold(
        appBar: AppBar(title: const Text(PaymentStrings.subscriptionTitle)),
        body: BlocConsumer<SubscriptionCubit, SubscriptionState>(
          listenWhen: (p, c) =>
              p.flow != c.flow && c.flow == SubscriptionFlow.checkoutReady,
          listener: (context, state) async {
            final cubit = context.read<SubscriptionCubit>();
            final url = state.session?.checkoutUrl;
            if (url == null) return;
            await Navigator.of(context)
                .push<bool>(PaymobCheckoutPage.route(url));
            cubit.onCheckoutClosed();
          },
          builder: (context, state) {
            final cubit = context.read<SubscriptionCubit>();
            switch (state.flow) {
              case SubscriptionFlow.initial:
              case SubscriptionFlow.loading:
                return const Center(child: CircularProgressIndicator());
              case SubscriptionFlow.tracking:
                return PaymentStatusView(
                  kind: PaymentStatusKind.verifying,
                  slow: state.verifyingTooLong,
                );
              case SubscriptionFlow.activated:
                return PaymentStatusView(
                  kind: PaymentStatusKind.success,
                  onDone: cubit.backToReady,
                );
              case SubscriptionFlow.failed:
                return PaymentStatusView(
                  kind: PaymentStatusKind.failure,
                  failure: state.failure,
                  onRetry: () => cubit.load(ownerId),
                );
              case SubscriptionFlow.ready:
              case SubscriptionFlow.submitting:
              case SubscriptionFlow.checkoutReady:
                final busy = state.flow != SubscriptionFlow.ready;
                final hasActive =
                    state.subscription?.isActiveAt(DateTime.now()) ?? false;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SubscriptionStatusCard(subscription: state.subscription),
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      onChanged: cubit.setBillingEmail,
                      decoration: const InputDecoration(
                        labelText: 'Billing email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      PaymentStrings.choosePlan,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final plan in state.plans)
                      _PlanTile(
                        plan: plan,
                        busy:
                            busy ||
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(state.billingEmail.trim()),
                        renew: hasActive,
                        onTap: () => cubit.subscribe(plan.id),
                      ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.busy,
    required this.renew,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool busy;
  final bool renew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final interval = plan.interval == SubscriptionInterval.yearly
        ? PaymentStrings.yearly
        : PaymentStrings.monthly;
    return Card(
      child: ListTile(
        title: Text(plan.name),
        subtitle: Text('${formatEgp(plan.price)} • $interval'),
        trailing: FilledButton(
          onPressed: busy ? null : onTap,
          child: Text(renew ? PaymentStrings.renew : PaymentStrings.subscribe),
        ),
      ),
    );
  }
}

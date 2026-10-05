import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/payment_enums.dart';
import '../cubit/booking_payment_cubit.dart';
import '../cubit/booking_payment_state.dart';
import '../utils/money_format.dart';
import '../utils/payment_strings.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/payment_status_view.dart';
import 'paymob_checkout_page.dart';

/// Customer payment screen for ONE booking.
/// INTEGRATION POINT — REQUIRES EXISTING PROJECT VALUE: pass [bookingId], [shopId] and [totalPiasters]
/// from your booking model ([totalPiasters] is DISPLAY ONLY; the server computes the real amount).
class BookingPaymentPage extends StatelessWidget {
  const BookingPaymentPage({
    super.key,
    required this.bookingId,
    required this.shopId,
    required this.totalPiasters,
    this.onFinished,
  });

  final String bookingId;
  final String shopId;
  final int totalPiasters;

  /// Called when the user taps "Done" after success / cash recorded.
  final VoidCallback? onFinished;

  static Route<void> route({
    required String bookingId,
    required String shopId,
    required int totalPiasters,
    VoidCallback? onFinished,
  }) => MaterialPageRoute<void>(
    builder: (_) => BookingPaymentPage(
      bookingId: bookingId,
      shopId: shopId,
      totalPiasters: totalPiasters,
      onFinished: onFinished,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingPaymentCubit>(
      create: (_) => GetIt.I<BookingPaymentCubit>()..load(shopId),
      child: Scaffold(
        appBar: AppBar(title: const Text(PaymentStrings.payTitle)),
        body: BlocConsumer<BookingPaymentCubit, BookingPaymentState>(
          listenWhen: (p, c) =>
              p.flow != c.flow && c.flow == BookingPaymentFlow.checkoutReady,
          listener: (context, state) async {
            final cubit = context.read<BookingPaymentCubit>();
            final url = state.session?.checkoutUrl;
            if (url == null) return;
            await Navigator.of(context)
                .push<bool>(PaymobCheckoutPage.route(url));
            cubit.onCheckoutClosed();
          },
          builder: (context, state) {
            final cubit = context.read<BookingPaymentCubit>();
            switch (state.flow) {
              case BookingPaymentFlow.initial:
              case BookingPaymentFlow.loading:
                return const Center(child: CircularProgressIndicator());
              case BookingPaymentFlow.ready:
              case BookingPaymentFlow.submitting:
              case BookingPaymentFlow.checkoutReady:
                final submitting = state.flow != BookingPaymentFlow.ready;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      title: const Text(PaymentStrings.total),
                      trailing: Text(
                        formatEgp(totalPiasters),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    Text(
                      PaymentStrings.chooseMethod,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    PaymentMethodSelector(
                      options: state.options!,
                      selected: state.selected,
                      onChanged: cubit.select,
                    ),
                    if (state.selected == PaymentMethod.online) ...[
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
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          submitting ||
                              state.selected == null ||
                              (state.selected == PaymentMethod.online &&
                                  !cubit.hasValidBillingEmail)
                          ? null
                          : () => cubit.submit(bookingId),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              state.selected == PaymentMethod.cash
                                  ? PaymentStrings.confirmCash
                                  : PaymentStrings.payNow,
                            ),
                    ),
                  ],
                );
              case BookingPaymentFlow.tracking:
                return PaymentStatusView(
                  kind: PaymentStatusKind.verifying,
                  slow: state.verifyingTooLong,
                  onRefresh: cubit.refresh,
                );
              case BookingPaymentFlow.succeeded:
                return PaymentStatusView(
                  kind: PaymentStatusKind.success,
                  onDone: onFinished ?? () => Navigator.of(context).maybePop(),
                );
              case BookingPaymentFlow.cashRecorded:
                return PaymentStatusView(
                  kind: PaymentStatusKind.cash,
                  onDone: onFinished ?? () => Navigator.of(context).maybePop(),
                );
              case BookingPaymentFlow.failed:
                return PaymentStatusView(
                  kind: PaymentStatusKind.failure,
                  failure: state.failure,
                  onRetry: state.options == null
                      ? () => cubit.load(shopId)
                      : cubit.backToReady,
                );
            }
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/payout_destination.dart';
import '../cubit/payout_destination_cubit.dart';
import '../utils/payment_strings.dart';

/// Owner enters where settlements should be paid. Validated server-side (wallet number / IBAN checksum).
/// INTEGRATION POINT: pass the signed-in owner's uid as [ownerId].
class PayoutDestinationPage extends StatelessWidget {
  const PayoutDestinationPage({super.key, required this.ownerId});

  final String ownerId;

  static Route<void> route({required String ownerId}) =>
      MaterialPageRoute<void>(builder: (_) => PayoutDestinationPage(ownerId: ownerId));

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PayoutDestinationCubit>(
      create: (_) => GetIt.I<PayoutDestinationCubit>()..load(ownerId),
      child: Scaffold(
        appBar: AppBar(title: const Text(PaymentStrings.payoutTitle)),
        body: BlocConsumer<PayoutDestinationCubit, PayoutDestinationState>(
          listener: (context, state) {
            final cubit = context.read<PayoutDestinationCubit>();
            if (state.flow == PayoutDestinationFlow.saved) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(PaymentStrings.saved)));
              cubit.acknowledge();
            } else if (state.flow == PayoutDestinationFlow.failed && state.failure != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(PaymentStrings.errorFor(state.failure!))));
              cubit.acknowledge();
            }
          },
          builder: (context, state) {
            if (state.flow == PayoutDestinationFlow.loading) return const Center(child: CircularProgressIndicator());
            return _Form(
              key: ValueKey(state.destination),
              initial: state.destination,
              saving: state.flow == PayoutDestinationFlow.saving,
            );
          },
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({super.key, required this.initial, required this.saving});

  final PayoutDestination? initial;
  final bool saving;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late PayoutDestinationType _type = widget.initial?.type ?? PayoutDestinationType.wallet;
  late final TextEditingController _name = TextEditingController(text: widget.initial?.accountHolderName ?? '');
  late final TextEditingController _number = TextEditingController(
    text: widget.initial == null
        ? ''
        : (widget.initial!.type == PayoutDestinationType.wallet ? widget.initial!.walletMsisdn : widget.initial!.iban) ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  void _save() {
    final number = _number.text.replaceAll(RegExp(r'\s+'), '');
    context.read<PayoutDestinationCubit>().save(
          PayoutDestination(
            type: _type,
            accountHolderName: _name.text.trim(),
            walletMsisdn: _type == PayoutDestinationType.wallet ? number : null,
            iban: _type == PayoutDestinationType.iban ? number.toUpperCase() : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<PayoutDestinationType>(
          segments: const [
            ButtonSegment(value: PayoutDestinationType.wallet, label: Text(PaymentStrings.wallet)),
            ButtonSegment(value: PayoutDestinationType.iban, label: Text(PaymentStrings.iban)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: PaymentStrings.holderName)),
        const SizedBox(height: 12),
        TextField(
          controller: _number,
          keyboardType: _type == PayoutDestinationType.wallet ? TextInputType.phone : TextInputType.text,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: _type == PayoutDestinationType.wallet ? PaymentStrings.walletNumber : PaymentStrings.ibanNumber,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.saving ? null : _save,
          child: widget.saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(PaymentStrings.save),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.otpCode)),
      );
      return;
    }

    final cubit = context.read<AuthCubit>();
    await cubit.verifyOtp(code);

    if (!mounted) {
      return;
    }

    if (cubit.state is AuthAuthenticated) {
      context.go('/dashboard');
      return;
    }

    if (cubit.state is AuthError) {
      final errorMessage = (cubit.state as AuthError).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${loc.otpSentTo} ${widget.phoneNumber}'),
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              onCompleted: (value) => _verifyOtp(),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.underline,
                activeColor: Theme.of(context).colorScheme.primary,
                selectedColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context).colorScheme.outline,
                fieldHeight: 56,
                fieldWidth: 42,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                child: Text(loc.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}

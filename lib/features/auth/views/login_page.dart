import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _phoneNumber = '';

  Future<void> _sendCode() async {
    final phone = _phoneNumber.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.phoneNumber)),
      );
      return;
    }

    final cubit = context.read<AuthCubit>();
    await cubit.sendOtp(phone);

    if (!mounted) {
      return;
    }

    if (cubit.state is AuthCodeSent) {
      context.go('/otp?phone=${Uri.encodeComponent(phone)}');
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
            IntlPhoneField(
              decoration: InputDecoration(
                labelText: loc.phoneNumber,
                border: const OutlineInputBorder(),
              ),
              initialCountryCode: 'SA',
              onChanged: (phone) {
                _phoneNumber = phone.completeNumber;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendCode,
                child: Text(loc.sendCode),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

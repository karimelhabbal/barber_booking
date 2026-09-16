import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

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
      final loc = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.invalidPhoneNumber)));

      return;
    }

    await context.read<AuthCubit>().loginWithPhone(phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthCodeSent) {
          context.go('/otp?phone=${Uri.encodeComponent(state.phoneNumber)}');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.code.localizedMessage(loc))),
          );
        }
      },
      child: Scaffold(
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
                initialCountryCode: 'EG',
                onChanged: (phone) {
                  _phoneNumber = phone.completeNumber;
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendCode,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.sendCode),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: Text(loc.register),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  context.go('/barber-login');
                },
                icon: const Icon(Icons.content_cut),
                label: const Text('دخول الحلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

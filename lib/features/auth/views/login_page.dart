import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.read<AuthCubit>().loginWithPhone(phone: '+1000000000'),
          child: Text(loc.login),
        ),
      ),
    );
  }
}

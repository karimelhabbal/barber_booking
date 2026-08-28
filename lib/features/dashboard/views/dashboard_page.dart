import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.dashboard),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(loc.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          loc.welcomeBarberSaas,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

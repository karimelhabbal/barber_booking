import 'package:barber_booking/features/barber_shop/presentation/pages/owner_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import 'barber_dashboard_page.dart';
import 'customer_app_shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.user.role == UserRole.customer) {
      return const CustomerAppShell();
    }

    if (authState.user.role == UserRole.owner) {
      return const OwnerDashboardPage();
    }

    if (authState.user.role == UserRole.barber) {
      return const BarberDashboardPage();
    }

    return const Scaffold(body: Center(child: Text('Unsupported user role.')));
  }
}

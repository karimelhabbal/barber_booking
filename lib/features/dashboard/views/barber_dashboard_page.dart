import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';

part 'widgets/barber_dashboard_body.dart';
part 'widgets/barber_dashboard_scaffold.dart';
part 'widgets/booking_card.dart';
part 'widgets/status_chip.dart';
part 'widgets/summary_card.dart';
part 'widgets/summary_grid.dart';
part 'widgets/welcome_card.dart';

class BarberDashboardPage extends StatelessWidget {
  const BarberDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final shopId = user.barberShopId?.trim() ?? '';

    if (shopId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Barber Dashboard'),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your barber account is not assigned to a shop.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<BarberCubit>(
          create: (_) =>
              getIt<BarberCubit>()
                ..loadCurrentBarber(userId: user.id, barberShopId: shopId),
        ),
        BlocProvider<BarberShopCubit>(
          create: (_) => getIt<BarberShopCubit>()..loadShop(shopId: shopId),
        ),
      ],
      child: BlocBuilder<BarberCubit, BarberState>(
        builder: (context, barberState) {
          if (barberState is BarberProfileLoading ||
              barberState is BarberInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (barberState is BarberError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Barber Dashboard'),
                actions: [
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        barberState.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<BarberCubit>().loadCurrentBarber(
                              userId: user.id,
                              barberShopId: shopId,
                            ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (barberState is! BarberProfileLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final barber = barberState.barber;

          return BlocBuilder<BarberShopCubit, BarberShopState>(
            builder: (context, shopState) {
              if (shopState is BarberShopShopLoading ||
                  shopState is BarberShopInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (shopState is BarberShopError) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Barber Dashboard'),
                    actions: [
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shopState.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<BarberShopCubit>()
                                .loadShop(shopId: shopId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (shopState is! BarberShopShopLoaded) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return _BarberDashboardScaffold(
                barberId: barber.id,
                barberName: barber.name,
                shop: shopState.shop,
                onLogout: _logout,
              );
            },
          );
        },
      ),
    );
  }
}

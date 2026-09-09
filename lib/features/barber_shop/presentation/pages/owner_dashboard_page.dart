import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/auth/domain/entities/user.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:barber_booking/features/barber_shop/presentation/pages/owner_create_shop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_booking/features/barber/presentation/pages/owner_barbers_page.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    if (user.role != UserRole.owner) {
      return const Scaffold(body: Center(child: Text('Access denied.')));
    }

    return BlocProvider(
      create: (_) => getIt<BarberShopCubit>()..loadOwnerShop(ownerId: user.id),
      child: Scaffold(
        appBar: AppBar(title: const Text('Owner Dashboard')),
        body: BlocBuilder<BarberShopCubit, BarberShopState>(
          builder: (context, state) {
            if (state is BarberShopOwnerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BarberShopError) {
              return Center(child: Text(state.message));
            }

            if (state is BarberShopOwnerLoaded) {
              final shop = state.shop;

              if (shop == null) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final authCubit = context.read<AuthCubit>();

                      final createdShop = await Navigator.of(context)
                          .push<BarberShop>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OwnerCreateShopPage(authCubit: authCubit),
                            ),
                          );

                      if (!context.mounted) {
                        return;
                      }

                      if (createdShop != null) {
                        context.read<BarberShopCubit>().loadOwnerShop(
                          ownerId: user.id,
                        );
                      }
                    },
                    child: const Text('Create Barber Shop'),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(shop.address ?? 'No address'),
                    const SizedBox(height: 8),
                    Text(shop.phone ?? 'No phone'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                OwnerBarbersPage(barberShopId: shop.id),
                          ),
                        );
                      },
                      child: const Text('Manage Barbers'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

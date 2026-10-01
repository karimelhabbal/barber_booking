import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../notifications/presentation/pages/notifications_page.dart';
import 'barber_workspace_shell.dart';

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

  String _barberErrorMessage(BarberErrorCode code, AppLocalizations loc) {
    switch (code) {
      case BarberErrorCode.barberIdEmpty:
        return loc.barberIdCannotBeEmpty;

      case BarberErrorCode.userIdEmpty:
        return loc.userIdCannotBeEmpty;

      case BarberErrorCode.shopIdEmpty:
        return loc.barberShopIdCannotBeEmpty;

      case BarberErrorCode.nameEmpty:
        return loc.barberNameCannotBeEmpty;

      case BarberErrorCode.userNotFound:
        return loc.barberUserNotFound;

      case BarberErrorCode.userNotBarber:
        return loc.selectedUserIsNotBarber;

      case BarberErrorCode.assignedAnotherShop:
        return loc.barberAssignedToAnotherShop;

      case BarberErrorCode.assignedThisShop:
        return loc.barberAlreadyAssignedToShop;

      case BarberErrorCode.barberNotFound:
        return loc.barberNotFound;

      case BarberErrorCode.barberUserIdMissing:
        return loc.barberUserIdMissing;

      case BarberErrorCode.barberShopIdMissing:
        return loc.barberShopIdMissing;

      case BarberErrorCode.profileNotFound:
        return loc.barberProfileNotFound;

      case BarberErrorCode.unknown:
        return loc.unknownError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final shopId = user.barberShopId?.trim() ?? '';

    if (shopId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.barberDashboardTitle),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              tooltip: loc.logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loc.barberAccountNotAssignedToShop,
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
                title: Text(loc.barberDashboardTitle),
                actions: [
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    tooltip: loc.logout,
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
                        _barberErrorMessage(barberState.code, loc),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<BarberCubit>().loadCurrentBarber(
                              userId: user.id,
                              barberShopId: shopId,
                            ),
                        child: Text(loc.retry),
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
                    title: Text(loc.barberDashboardTitle),
                    actions: [
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        tooltip: loc.logout,
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 42,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                loc.shopUnavailable,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                loc.barberWorkspaceUnavailable,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => context
                                      .read<BarberShopCubit>()
                                      .loadShop(shopId: shopId),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(loc.tryAgain),
                                ),
                              ),
                            ],
                          ),
                        ),
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

              return BarberWorkspaceShell(
                barberId: barber.id,
                barberName: barber.name,
                recipientId: user.id,
                shop: shopState.shop,
              );
            },
          );
        },
      ),
    );
  }
}

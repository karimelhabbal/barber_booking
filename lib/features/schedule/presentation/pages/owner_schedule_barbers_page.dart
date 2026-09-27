import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'owner_schedule_page.dart';

/// Owner entry point for schedule management.
///
/// Lets the owner pick a barber before editing the weekly schedule, breaks
/// and schedule exceptions of that barber.
class OwnerScheduleBarbersPage extends StatelessWidget {
  const OwnerScheduleBarbersPage({super.key, required this.barberShopId});

  final String barberShopId;

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
    return BlocProvider(
      create: (_) =>
          getIt<BarberCubit>()..loadShopBarbers(barberShopId: barberShopId),
      child: Builder(
        builder: (context) {
          final loc = AppLocalizations.of(context)!;

          return Scaffold(
            appBar: AppBar(
              title: Text(loc.manageSchedule),
              actions: [
                IconButton(
                  onPressed: () => context.read<BarberCubit>().loadShopBarbers(
                    barberShopId: barberShopId,
                  ),
                  icon: const Icon(Icons.refresh),
                  tooltip: loc.refresh,
                ),
              ],
            ),
            body: BlocBuilder<BarberCubit, BarberState>(
              builder: (context, state) {
                if (state is BarberLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BarberError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _barberErrorMessage(state.code, loc),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<BarberCubit>()
                                .loadShopBarbers(barberShopId: barberShopId),
                            child: Text(loc.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is BarberLoaded) {
                  if (state.barbers.isEmpty) {
                    return Center(child: Text(loc.noBarbersForSchedule));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.barbers.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      final barber = state.barbers[index];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              barber.name.isNotEmpty
                                  ? barber.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(barber.name),
                          subtitle: Text(loc.manageWeeklyHours),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OwnerSchedulePage(
                                  barberId: barber.id,
                                  barberName: barber.name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/service/presentation/pages/customer_services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerShopPage extends StatelessWidget {
  const CustomerShopPage({super.key, required this.shop});

  final BarberShop shop;

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

    return BlocProvider(
      create: (_) =>
          getIt<BarberCubit>()..loadShopBarbers(barberShopId: shop.id),
      child: Scaffold(
        appBar: AppBar(title: Text(shop.name)),
        body: BlocBuilder<BarberCubit, BarberState>(
          builder: (context, state) {
            if (state is BarberLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BarberError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _barberErrorMessage(state.code, loc),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state is BarberLoaded) {
              if (state.barbers.isEmpty) {
                return Center(
                  child: Text(
                    loc.noBarbersCurrentlyAvailable,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.barbers.length,
                itemBuilder: (context, index) {
                  final barber = state.barbers[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            barber.imageUrl != null &&
                                barber.imageUrl!.trim().isNotEmpty
                            ? NetworkImage(barber.imageUrl!)
                            : null,
                        child:
                            barber.imageUrl == null ||
                                barber.imageUrl!.trim().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(barber.name),
                      subtitle: Text(barber.phone ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerServicesPage(
                              shop: shop,
                              barber: barber,
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
      ),
    );
  }
}

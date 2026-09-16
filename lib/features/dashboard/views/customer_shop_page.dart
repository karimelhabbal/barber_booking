import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/service/presentation/pages/customer_services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerShopPage extends StatelessWidget {
  const CustomerShopPage({super.key, required this.shop});

  final BarberShop shop;

  @override
  Widget build(BuildContext context) {
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
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }

            if (state is BarberLoaded) {
              if (state.barbers.isEmpty) {
                return const Center(
                  child: Text(
                    'No barbers are currently available.',
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

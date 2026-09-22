import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber/presentation/pages/owner_create_barber_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../schedule/presentation/pages/owner_schedule_page.dart';
import '../../domain/entities/barber.dart';

class OwnerBarbersPage extends StatelessWidget {
  const OwnerBarbersPage({super.key, required this.barberShopId});

  final String barberShopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BarberCubit>()..loadShopBarbers(barberShopId: barberShopId),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Barbers')),
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
                          Text(state.message),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<BarberCubit>()
                                .loadShopBarbers(barberShopId: barberShopId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is BarberLoaded) {
                  if (state.barbers.isEmpty) {
                    return const Center(child: Text('No barbers yet.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.barbers.length,
                    separatorBuilder: (_, _) {
                      return const SizedBox(height: 8);
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
                          subtitle: Text(barber.phone ?? 'No phone'),
                          trailing: Switch(
                            value: barber.isActive,
                            onChanged: (value) {
                              context.read<BarberCubit>().updateBarber(
                                Barber(
                                  id: barber.id,
                                  userId: barber.userId,
                                  barberShopId: barber.barberShopId,
                                  name: barber.name,
                                  phone: barber.phone,
                                  imageUrl: barber.imageUrl,
                                  isActive: value,
                                  createdAt: barber.createdAt,
                                  updatedAt: DateTime.now(),
                                ),
                              );
                            },
                          ),
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
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final createdBarber = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OwnerCreateBarberPage(barberShopId: barberShopId),
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                if (createdBarber != null) {
                  await context.read<BarberCubit>().loadShopBarbers(
                    barberShopId: barberShopId,
                  );
                }
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

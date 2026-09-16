import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/features/barber/domain/entities/barber.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/booking/views/booking_page.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerServicesPage extends StatelessWidget {
  const CustomerServicesPage({
    super.key,
    required this.shop,
    required this.barber,
  });

  final BarberShop shop;
  final Barber barber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ServiceCubit>()..loadActiveShopServices(shopId: shop.id),
      child: Scaffold(
        appBar: AppBar(title: Text(shop.name)),
        body: BlocBuilder<ServiceCubit, ServiceState>(
          builder: (context, state) {
            if (state is ServiceLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ServiceError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }

            if (state is ServiceLoaded) {
              if (state.services.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No services are currently available.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return _ServicesList(
                shop: shop,
                barber: barber,
                services: state.services,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  const _ServicesList({
    required this.shop,
    required this.barber,
    required this.services,
  });

  final BarberShop shop;
  final Barber barber;
  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = services[index];

        return _ServiceCard(
          service: service,
          onTap: () {
            _selectService(context, service);
          },
        );
      },
    );
  }

  void _selectService(BuildContext context, Service service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BookingPage(shop: shop, barber: barber, service: service),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${service.price.toStringAsFixed(2)} EGP',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (service.description != null &&
                  service.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(service.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(_formatDuration(service.durationMinutes)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    return '${hours}h ${remainingMinutes}min';
  }
}

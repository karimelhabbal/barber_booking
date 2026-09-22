part of '../customer_dashboard_page.dart';

class _BarberSectionContent extends StatelessWidget {
  const _BarberSectionContent({
    required this.shop,
    required this.barbers,
    required this.barberState,
    required this.selectedBarber,
    required this.onBarberSelected,
    required this.loc,
  });

  final BarberShop shop;
  final List<Barber> barbers;
  final BarberState barberState;
  final Barber? selectedBarber;
  final ValueChanged<Barber> onBarberSelected;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    if (barberState is BarberLoading) {
      return LoadingView(message: loc.loadingBarbers);
    }

    if (barberState is BarberError) {
      return ErrorView(
        title: loc.loadBarbersError,
        message: loc.loadBarbersError,
        onRetry: () =>
            context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id),
        retryLabel: loc.retry,
      );
    }

    if (barberState is! BarberLoaded && barberState is! BarberLoading) {
      return ErrorView(
        title: loc.loadBarbersError,
        message: loc.loadBarbersError,
        onRetry: () =>
            context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id),
        retryLabel: loc.retry,
      );
    }

    if (barbers.isEmpty) {
      return EmptyView(
        title: loc.noActiveBarbers,
        message: loc.noBarbersMessage,
        icon: Icons.person_search_outlined,
      );
    }

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: barbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final barber = barbers[index];

          return _BarberCard(
            barber: barber,
            isSelected: selectedBarber?.id == barber.id,
            onTap: () => onBarberSelected(barber),
          );
        },
      ),
    );
  }
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  final Barber barber;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = barber.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return SizedBox(
      width: 164,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials.isEmpty ? 'B' : initials,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.background),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  barber.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (barber.phone != null &&
                    barber.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    barber.phone!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceSectionContent extends StatelessWidget {
  const _ServiceSectionContent({
    required this.services,
    required this.serviceState,
    required this.shop,
    required this.loc,
  });

  final List<Service> services;
  final ServiceState serviceState;
  final BarberShop shop;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    if (serviceState is ServiceLoading) {
      return LoadingView(message: loc.loadingServices);
    }

    if (serviceState is ServiceError) {
      return ErrorView(
        title: loc.loadServicesError,
        message: loc.loadServicesError,
        onRetry: () => context.read<ServiceCubit>().loadActiveShopServices(
          shopId: shop.id,
        ),
        retryLabel: loc.retry,
      );
    }

    if (serviceState is! ServiceLoaded && serviceState is! ServiceLoading) {
      return ErrorView(
        title: loc.loadServicesError,
        message: loc.loadServicesError,
        onRetry: () => context.read<ServiceCubit>().loadActiveShopServices(
          shopId: shop.id,
        ),
        retryLabel: loc.retry,
      );
    }

    if (services.isEmpty) {
      return EmptyView(
        title: loc.noServicesAvailable,
        message: loc.noServicesMessage,
        icon: Icons.miscellaneous_services_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final service = services[index];

        return AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (service.description != null &&
                        service.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${_durationLabel(service.durationMinutes, loc)} • ${service.price.toStringAsFixed(2)} EGP',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _durationLabel(int minutes, AppLocalizations loc) {
    if (minutes < 60) {
      return '$minutes ${loc.minutes}';
    }

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (remainder == 0) {
      return hours == 1 ? '1 ${loc.hour}' : '$hours ${loc.hours}';
    }

    return '$hours${loc.hourShort} $remainder ${loc.minutes}';
  }
}

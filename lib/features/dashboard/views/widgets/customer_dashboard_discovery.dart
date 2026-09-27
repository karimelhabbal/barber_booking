part of '../customer_dashboard_page.dart';

/// Home browsing categories behind the horizontal filter chips.
///
/// A service document has no stored category, so the filter matches keywords in
/// the service name/description in both supported languages.
enum _ServiceCategory {
  all(<String>[]),
  haircut(<String>['hair', 'fade', 'cut', 'شعر', 'قص']),
  beard(<String>['beard', 'stubble', 'لحية', 'ذقن']),
  shave(<String>['shave', 'razor', 'حلاقة', 'موس']),
  packages(<String>['package', 'bundle', 'combo', 'باقة', 'باقات', 'عرض']);

  const _ServiceCategory(this.keywords);

  final List<String> keywords;

  bool matches(Service service) {
    if (this == _ServiceCategory.all) {
      return true;
    }

    final haystack = '${service.name} ${service.description ?? ''}'
        .toLowerCase();

    return keywords.any((keyword) => haystack.contains(keyword));
  }
}

String _categoryLabel(_ServiceCategory category, AppLocalizations loc) {
  switch (category) {
    case _ServiceCategory.all:
      return loc.categoryAll;
    case _ServiceCategory.haircut:
      return loc.categoryHaircut;
    case _ServiceCategory.beard:
      return loc.categoryBeard;
    case _ServiceCategory.shave:
      return loc.categoryShave;
    case _ServiceCategory.packages:
      return loc.categoryPackages;
  }
}

class _ServiceCategoryChips extends StatelessWidget {
  const _ServiceCategoryChips({
    required this.selectedIndex,
    required this.onSelected,
    required this.loc,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _ServiceCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _ServiceCategory.values[index];
          final isSelected = index == selectedIndex;

          return FilterChip(
            label: Text(_categoryLabel(category, loc)),
            selected: isSelected,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => onSelected(index),
            selectedColor: AppColors.primarySoft,
            backgroundColor: theme.colorScheme.surface,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : theme.colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }
}

class _BarberSectionContent extends StatelessWidget {
  const _BarberSectionContent({
    required this.shop,
    required this.barbers,
    required this.barberState,
    required this.selectedBarber,
    required this.onBarberSelected,
    required this.isFiltered,
    required this.loc,
  });

  final BarberShop shop;
  final List<Barber> barbers;
  final BarberState barberState;
  final Barber? selectedBarber;
  final ValueChanged<Barber> onBarberSelected;
  final bool isFiltered;
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
        message: isFiltered ? null : loc.noBarbersMessage,
        icon: Icons.person_search_outlined,
      );
    }

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: barbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final barber = barbers[index];

          return _BarberCard(
            barber: barber,
            isSelected: selectedBarber?.id == barber.id,
            onTap: () {
              onBarberSelected(barber);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerServicesPage(shop: shop, barber: barber),
                ),
              );
            },
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
    final theme = Theme.of(context);
    final initials = _barberInitials(barber.name);

    return SizedBox(
      width: 156,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  barber.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (barber.phone != null &&
                    barber.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    barber.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
    required this.barber,
    required this.isFiltered,
    required this.loc,
  });

  final List<Service> services;
  final ServiceState serviceState;
  final BarberShop shop;
  final Barber? barber;
  final bool isFiltered;
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
        title: isFiltered ? loc.noServicesFound : loc.noServicesAvailable,
        message: isFiltered ? null : loc.noServicesMessage,
        icon: Icons.miscellaneous_services_outlined,
      );
    }

    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final service = services[index];

          return _ServiceCard(
            service: service,
            loc: loc,
            onBook: barber == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingPage(
                          shop: shop,
                          barber: barber!,
                          service: service,
                        ),
                      ),
                    );
                  },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.loc,
    required this.onBook,
  });

  final Service service;
  final AppLocalizations loc;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (service.description != null &&
                  service.description!.trim().isNotEmpty)
                Text(
                  service.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${service.price.toStringAsFixed(2)} ${loc.currency}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _durationLabel(service.durationMinutes, loc),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    loc.bookNow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

String _barberInitials(String name) {
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  return initials.isEmpty ? 'B' : initials;
}

class _TeamSheet extends StatelessWidget {
  const _TeamSheet({
    required this.barbers,
    required this.selectedBarberId,
    required this.loc,
  });

  final List<Barber> barbers;
  final String? selectedBarberId;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(loc.topBarbers, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: barbers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final barber = barbers[index];

                return _TeamTile(
                  barber: barber,
                  isSelected: barber.id == selectedBarberId,
                  onTap: () => Navigator.of(context).pop(barber),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.barber,
    required this.isSelected,
    required this.onTap,
  });

  final Barber barber;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final phone = barber.phone?.trim();

    return ListTile(
      onTap: onTap,
      tileColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          _barberInitials(barber.name),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(barber.name, style: theme.textTheme.titleMedium),
      subtitle: Text(
        phone == null || phone.isEmpty ? loc.noPhone : phone,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
    );
  }
}

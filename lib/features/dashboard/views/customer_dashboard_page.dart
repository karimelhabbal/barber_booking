import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/theme/app_theme.dart';
import 'package:barber_booking/core/widgets/app_button.dart';
import 'package:barber_booking/core/widgets/app_card.dart';
import 'package:barber_booking/core/widgets/empty_view.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/core/widgets/status_chip.dart';
import 'package:barber_booking/features/barber/domain/entities/barber.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:barber_booking/features/service/presentation/pages/customer_services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: LoadingView(message: 'Loading your dashboard...'),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<BarberShopCubit>()..loadActiveShops(),
        ),
        BlocProvider(
          create: (_) =>
              getIt<BookingCubit>()
                ..loadCustomerBookings(customerId: authState.user.id),
        ),
        BlocProvider(create: (_) => getIt<BarberCubit>()),
        BlocProvider(create: (_) => getIt<ServiceCubit>()),
      ],
      child: _CustomerDashboardView(
        customerId: authState.user.id,
        customerName: authState.user.name,
      ),
    );
  }
}

class _CustomerDashboardView extends StatelessWidget {
  const _CustomerDashboardView({
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarberShopCubit, BarberShopState>(
      listener: (context, state) {
        if (state is! BarberShopLoaded || state.shops.isEmpty) {
          return;
        }

        final shop = state.shops.first;
        context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id);
        context.read<ServiceCubit>().loadActiveShopServices(shopId: shop.id);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<BarberShopCubit>().loadActiveShops();
              context.read<BookingCubit>().loadCustomerBookings(
                customerId: customerId,
              );

              final shopState = context.read<BarberShopCubit>().state;
              if (shopState is BarberShopLoaded && shopState.shops.isNotEmpty) {
                final shop = shopState.shops.first;
                context.read<BarberCubit>().loadShopBarbers(
                  barberShopId: shop.id,
                );
                context.read<ServiceCubit>().loadActiveShopServices(
                  shopId: shop.id,
                );
              }
            },
            child: _DashboardContent(
              customerId: customerId,
              customerName: customerName,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String? customerName;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  Barber? _selectedBarber;

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<BarberShopCubit>().state;
    final bookingState = context.watch<BookingCubit>().state;
    final barberState = context.watch<BarberCubit>().state;
    final serviceState = context.watch<ServiceCubit>().state;

    if (shopState is BarberShopLoading) {
      return const LoadingView(message: 'Loading your home...');
    }

    if (shopState is BarberShopError) {
      return ErrorView(
        title: 'Unable to load your dashboard',
        message: shopState.message,
        onRetry: () => context.read<BarberShopCubit>().loadActiveShops(),
      );
    }

    if (shopState is! BarberShopLoaded) {
      return const SizedBox.shrink();
    }

    final shops = shopState.shops;

    if (shops.isEmpty) {
      return const EmptyView(
        title: 'No active shops right now',
        message: 'Please check back later for available barbers.',
        icon: Icons.storefront_outlined,
      );
    }

    final shop = shops.first;
    final upcomingBooking = _upcomingBooking(bookingState);
    final barbers = _activeBarbers(barberState);
    final services = _activeServices(serviceState);

    _syncSelectedBarber(barbers);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Header(customerName: widget.customerName, shopName: shop.name),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Upcoming Appointment'),
        const SizedBox(height: 12),
        upcomingBooking == null
            ? const EmptyView(
                title: 'No upcoming appointment',
                message: 'Your next booking will appear here.',
                icon: Icons.event_available_outlined,
              )
            : _AppointmentCard(booking: upcomingBooking),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Barber Selection'),
        const SizedBox(height: 12),
        _BarberSectionContent(
          shop: shop,
          barbers: barbers,
          barberState: barberState,
          selectedBarber: _selectedBarber,
          onBarberSelected: _selectBarber,
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Services'),
        const SizedBox(height: 12),
        _ServiceSectionContent(
          services: services,
          serviceState: serviceState,
          shop: shop,
        ),
        const SizedBox(height: 24),
        _BookAppointmentAction(shop: shop, barber: _selectedBarber),
      ],
    );
  }

  void _syncSelectedBarber(List<Barber> barbers) {
    if (barbers.isEmpty) {
      if (_selectedBarber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedBarber = null;
            });
          }
        });
      }
      return;
    }

    final selectedId = _selectedBarber?.id;

    if (selectedId != null &&
        barbers.any((barber) => barber.id == selectedId)) {
      return;
    }

    final firstBarber = barbers.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedBarber = firstBarber;
        });
      }
    });
  }

  void _selectBarber(Barber barber) {
    setState(() {
      _selectedBarber = barber;
    });
  }

  Booking? _upcomingBooking(BookingState state) {
    if (state is! BookingLoaded) {
      return null;
    }

    final now = DateTime.now();

    final upcoming =
        state.bookings
            .where(
              (booking) =>
                  booking.status != BookingStatus.cancelled &&
                  booking.status != BookingStatus.completed &&
                  booking.status != BookingStatus.noShow &&
                  (booking.bookingDate.isAfter(now) ||
                      (booking.bookingDate.isAtSameMomentAs(now) &&
                          _timeToMinutes(booking.startTime) >=
                              _timeToMinutes(_currentTimeValue()))),
            )
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    if (upcoming.isEmpty) {
      return null;
    }

    return upcoming.first;
  }

  List<Barber> _activeBarbers(BarberState state) {
    if (state is! BarberLoaded) {
      return const <Barber>[];
    }

    return state.barbers.where((barber) => barber.isActive).toList();
  }

  List<Service> _activeServices(ServiceState state) {
    if (state is! ServiceLoaded) {
      return const <Service>[];
    }

    return state.services.where((service) => service.isActive).toList();
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return (hour * 60) + minute;
  }

  String _currentTimeValue() {
    final now = DateTime.now();

    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.customerName, required this.shopName});

  final String? customerName;
  final String shopName;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();

    final name = (customerName != null && customerName!.trim().isNotEmpty)
        ? customerName!.trim()
        : 'Customer';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryHighlight,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shopName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 18) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusChip(
                status: booking.status.name,
                label: _statusLabel(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(booking.barberName)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_dateLabel(booking.bookingDate)} • ${booking.startTime} - ${booking.endTime}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${booking.serviceDurationMinutes} min • ${booking.servicePrice.toStringAsFixed(2)} EGP',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.noShow:
        return 'No show';
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _BarberSectionContent extends StatelessWidget {
  const _BarberSectionContent({
    required this.shop,
    required this.barbers,
    required this.barberState,
    required this.selectedBarber,
    required this.onBarberSelected,
  });

  final BarberShop shop;
  final List<Barber> barbers;
  final BarberState barberState;
  final Barber? selectedBarber;
  final ValueChanged<Barber> onBarberSelected;

  @override
  Widget build(BuildContext context) {
    if (barberState is BarberLoading) {
      return const LoadingView(message: 'Loading barbers...');
    }

    if (barberState is BarberError) {
      return ErrorView(
        title: 'Unable to load barbers.',
        message: 'Unable to load barbers.',
        onRetry: () =>
            context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id),
      );
    }

    if (barberState is! BarberLoaded && barberState is! BarberLoading) {
      return ErrorView(
        title: 'Unable to load barbers.',
        message: 'Unable to load barbers.',
        onRetry: () =>
            context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id),
      );
    }

    if (barbers.isEmpty) {
      return const EmptyView(
        title: 'No active barbers',
        message: 'There are no barbers available for this shop right now.',
        icon: Icons.person_search_outlined,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: barbers
          .map(
            (barber) => _BarberCard(
              barber: barber,
              isSelected: selectedBarber?.id == barber.id,
              onTap: () => onBarberSelected(barber),
            ),
          )
          .toList(),
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
      width: 160,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials.isEmpty ? 'B' : initials,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: AppColors.background),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: barber.isActive
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surface3,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        barber.isActive ? 'Available' : 'Busy',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: barber.isActive
                              ? AppColors.primaryHighlight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  barber.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (barber.phone != null &&
                    barber.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    barber.phone!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
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
  });

  final List<Service> services;
  final ServiceState serviceState;
  final BarberShop shop;

  @override
  Widget build(BuildContext context) {
    if (serviceState is ServiceLoading) {
      return const LoadingView(message: 'Loading services...');
    }

    if (serviceState is ServiceError) {
      return ErrorView(
        title: 'Unable to load services.',
        message: 'Unable to load services.',
        onRetry: () => context.read<ServiceCubit>().loadActiveShopServices(
          shopId: shop.id,
        ),
      );
    }

    if (serviceState is! ServiceLoaded && serviceState is! ServiceLoading) {
      return ErrorView(
        title: 'Unable to load services.',
        message: 'Unable to load services.',
        onRetry: () => context.read<ServiceCubit>().loadActiveShopServices(
          shopId: shop.id,
        ),
      );
    }

    if (services.isEmpty) {
      return const EmptyView(
        title: 'No services available',
        message: 'This shop is not offering any active services right now.',
        icon: Icons.miscellaneous_services_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = services[index];

        return AppCard(
          padding: const EdgeInsets.all(14),
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
                      const SizedBox(height: 6),
                      Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${_durationLabel(service.durationMinutes)} • ${service.price.toStringAsFixed(2)} EGP',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.primaryHighlight),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (remainder == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    return '${hours}h ${remainder}min';
  }
}

class _BookAppointmentAction extends StatelessWidget {
  const _BookAppointmentAction({required this.shop, required this.barber});

  final BarberShop shop;
  final Barber? barber;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Book Appointment',
      onPressed: barber == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerServicesPage(shop: shop, barber: barber!),
                ),
              );
            },
    );
  }
}

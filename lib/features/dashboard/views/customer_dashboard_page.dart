import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
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
import 'package:barber_booking/features/notifications/presentation/pages/notifications_page.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:barber_booking/features/service/presentation/pages/customer_services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../booking/views/booking_page.dart';

part 'widgets/customer_dashboard_header.dart';
part 'widgets/customer_dashboard_appointment.dart';
part 'widgets/customer_dashboard_discovery.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return Scaffold(body: LoadingView(message: loc.loadingDashboard));
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<BarberShopCubit>().state;
    final bookingState = context.watch<BookingCubit>().state;
    final barberState = context.watch<BarberCubit>().state;
    final serviceState = context.watch<ServiceCubit>().state;
    final loc = AppLocalizations.of(context)!;

    if (shopState is BarberShopLoading) {
      return LoadingView(message: loc.loadingHome);
    }

    if (shopState is BarberShopError) {
      return ErrorView(
        title: loc.dashboardLoadError,
        message: shopState.message,
        onRetry: () => context.read<BarberShopCubit>().loadActiveShops(),
        retryLabel: loc.retry,
      );
    }

    if (shopState is! BarberShopLoaded) {
      return const SizedBox.shrink();
    }

    final shops = shopState.shops;

    if (shops.isEmpty) {
      return EmptyView(
        title: loc.noBarberShopsAvailable,
        message: loc.availableBarbersLater,
        icon: Icons.storefront_outlined,
      );
    }

    final shop = shops.first;
    final upcomingBooking = _upcomingBooking(bookingState);
    final barbers = _activeBarbers(barberState);
    final services = _activeServices(serviceState);

    _syncSelectedBarber(barbers);

    final displayBarbers = _filterBarbers(barbers);
    final displayServices = _filterServices(services);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Header(
            customerName: widget.customerName,
            shopName: shop.name,
            loc: loc,
            onNotifications: () => _openNotifications(context),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _HomeSearchField(
            controller: _searchController,
            hintText: loc.searchServices,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeader(title: loc.upcomingAppointment),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: upcomingBooking == null
              ? EmptyView(
                  title: loc.noUpcomingAppointment,
                  message: loc.nextBookingMessage,
                  icon: Icons.event_available_outlined,
                )
              : _AppointmentCard(booking: upcomingBooking),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeader(
            title: loc.popularServices,
            actionLabel: _selectedBarber == null ? null : loc.seeAll,
            onAction: _selectedBarber == null
                ? null
                : () => _openAllServices(context, shop, _selectedBarber),
          ),
        ),
        const SizedBox(height: 16),
        _ServiceCategoryChips(
          selectedIndex: _selectedCategoryIndex,
          onSelected: (index) => setState(() => _selectedCategoryIndex = index),
          loc: loc,
        ),
        const SizedBox(height: 24),
        _ServiceSectionContent(
          services: displayServices,
          serviceState: serviceState,
          shop: shop,
          barber: _selectedBarber,
          isFiltered: _hasActiveFilter,
          loc: loc,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeader(
            title: loc.topBarbers,
            actionLabel: displayBarbers.isEmpty ? null : loc.viewTeam,
            onAction: displayBarbers.isEmpty
                ? null
                : () => _openTeamSheet(context, displayBarbers),
          ),
        ),
        _BarberSectionContent(
          shop: shop,
          barbers: displayBarbers,
          barberState: barberState,
          selectedBarber: _selectedBarber,
          onBarberSelected: _selectBarber,
          isFiltered: _hasActiveFilter,
          loc: loc,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _BookAppointmentAction(shop: shop, barber: _selectedBarber),
        ),
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

  bool get _hasActiveFilter =>
      _selectedCategoryIndex != 0 || _searchQuery.isNotEmpty;

  void _openAllServices(BuildContext context, BarberShop shop, Barber? barber) {
    if (barber == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerServicesPage(shop: shop, barber: barber),
      ),
    );
  }

  Future<void> _openTeamSheet(
    BuildContext context,
    List<Barber> barbers,
  ) async {
    final loc = AppLocalizations.of(context)!;

    final selected = await showModalBottomSheet<Barber>(
      context: context,
      showDragHandle: true,
      builder: (_) => _TeamSheet(
        barbers: barbers,
        selectedBarberId: _selectedBarber?.id,
        loc: loc,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    _selectBarber(selected);
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(recipientId: widget.customerId),
      ),
    );
  }

  List<Service> _filterServices(List<Service> services) {
    final category = _ServiceCategory.values[_selectedCategoryIndex];
    final query = _searchQuery.toLowerCase();

    return services.where((service) {
      if (!category.matches(service)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return service.name.toLowerCase().contains(query) ||
          (service.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Barber> _filterBarbers(List<Barber> barbers) {
    final query = _searchQuery.toLowerCase();

    if (query.isEmpty) {
      return barbers;
    }

    return barbers
        .where(
          (barber) =>
              barber.name.toLowerCase().contains(query) ||
              (barber.phone?.toLowerCase().contains(query) ?? false),
        )
        .toList();
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

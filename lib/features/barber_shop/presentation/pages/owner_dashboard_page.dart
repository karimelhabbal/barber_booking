import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/widgets/app_button.dart';
import 'package:barber_booking/core/widgets/app_card.dart';
import 'package:barber_booking/core/widgets/empty_view.dart';
import 'package:barber_booking/core/widgets/error_view.dart';
import 'package:barber_booking/core/widgets/loading_view.dart';
import 'package:barber_booking/features/auth/domain/entities/user.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/barber/domain/entities/barber.dart';
import 'package:barber_booking/features/barber/presentation/cubit/barber_cubit.dart';
import 'package:barber_booking/features/barber/presentation/pages/owner_barbers_page.dart';
import 'package:barber_booking/features/barber_shop/domain/entities/barber_shop.dart';
import 'package:barber_booking/features/barber_shop/presentation/cubit/barber_shop_cubit.dart';
import 'package:barber_booking/features/barber_shop/presentation/pages/owner_create_shop_page.dart';
import 'package:barber_booking/features/booking/domain/entities/booking.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:barber_booking/features/booking/presentation/cubit/booking_state.dart';
import 'package:barber_booking/features/booking/views/owner_bookings_page.dart';
import 'package:barber_booking/features/schedule/presentation/pages/owner_schedule_barbers_page.dart';
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:barber_booking/features/service/presentation/pages/owner_services_page.dart';
import 'package:barber_booking/features/settings/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    if (user.role != UserRole.owner) {
      final loc = AppLocalizations.of(context)!;
      return Scaffold(body: Center(child: Text(loc.accessDenied)));
    }

    return BlocProvider(
      create: (_) => getIt<BarberShopCubit>()..loadOwnerShop(ownerId: user.id),
      child: _OwnerWorkspace(ownerId: user.id),
    );
  }
}

class _OwnerWorkspace extends StatefulWidget {
  const _OwnerWorkspace({required this.ownerId});

  final String ownerId;

  @override
  State<_OwnerWorkspace> createState() => _OwnerWorkspaceState();
}

class _OwnerWorkspaceState extends State<_OwnerWorkspace> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocBuilder<BarberShopCubit, BarberShopState>(
      builder: (context, state) {
        if (state is BarberShopInitial || state is BarberShopOwnerLoading) {
          return Scaffold(body: LoadingView(message: loc.loadingHome));
        }

        if (state is BarberShopError) {
          return Scaffold(
            body: ErrorView(
              title: loc.shopLoadError,
              message: state.message,
              retryLabel: loc.retry,
              onRetry: () => context.read<BarberShopCubit>().loadOwnerShop(
                ownerId: widget.ownerId,
              ),
            ),
          );
        }

        final shop = state is BarberShopOwnerLoaded ? state.shop : null;

        if (shop == null) {
          return Scaffold(body: _NoShopView(ownerId: widget.ownerId));
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _OwnerOverviewTab(shop: shop),
              OwnerBarbersPage(barberShopId: shop.id),
              OwnerServicesPage(shopId: shop.id),
              OwnerBookingsPage(shopId: shop.id),
              OwnerScheduleBarbersPage(barberShopId: shop.id),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _selectTab,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: loc.ownerNavDashboard,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.group_outlined),
                activeIcon: const Icon(Icons.group),
                label: loc.barbers,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.design_services_outlined),
                activeIcon: const Icon(Icons.design_services),
                label: loc.services,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: loc.bookings,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.schedule_outlined),
                activeIcon: const Icon(Icons.schedule),
                label: loc.ownerNavSchedule,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoShopView extends StatelessWidget {
  const _NoShopView({required this.ownerId});

  final String ownerId;

  Future<void> _createShop(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();

    final createdShop = await Navigator.of(context).push<BarberShop>(
      MaterialPageRoute(
        builder: (_) => OwnerCreateShopPage(authCubit: authCubit),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (createdShop != null) {
      await context.read<BarberShopCubit>().loadOwnerShop(ownerId: ownerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return EmptyView(
      icon: Icons.storefront_outlined,
      title: loc.createShopTitle,
      message: loc.createShopSubtitle,
      action: AppButton(
        label: loc.createShop,
        icon: Icons.add_business_outlined,
        onPressed: () => _createShop(context),
      ),
    );
  }
}

class _OwnerOverviewTab extends StatelessWidget {
  const _OwnerOverviewTab({required this.shop});

  final BarberShop shop;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<BarberCubit>()..loadShopBarbers(barberShopId: shop.id),
        ),
        BlocProvider(
          create: (_) =>
              getIt<ServiceCubit>()..loadShopServices(shopId: shop.id),
        ),
        BlocProvider(
          create: (_) =>
              getIt<BookingCubit>()..loadOwnerBookings(shopId: shop.id),
        ),
      ],
      child: _OwnerOverviewView(shop: shop),
    );
  }
}

class _OwnerOverviewView extends StatelessWidget {
  const _OwnerOverviewView({required this.shop});

  final BarberShop shop;

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<BarberCubit>().loadShopBarbers(barberShopId: shop.id),
      context.read<ServiceCubit>().loadShopServices(shopId: shop.id),
      context.read<BookingCubit>().loadOwnerBookings(shopId: shop.id),
    ]);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  Future<void> _logout(BuildContext context) {
    return context.read<AuthCubit>().logout();
  }

  String? _errorMessage(
    BarberState barberState,
    ServiceState serviceState,
    BookingState bookingState,
  ) {
    if (barberState is BarberError) {
      return barberState.message;
    }

    if (serviceState is ServiceError) {
      return serviceState.message;
    }

    if (bookingState is BookingError) {
      return bookingState.message;
    }

    return null;
  }

  double _revenue(List<Booking> bookings) {
    var total = 0.0;

    for (final booking in bookings) {
      if (booking.status == BookingStatus.completed) {
        total += booking.servicePrice;
      }
    }

    return total;
  }

  int _countByStatus(List<Booking> bookings, BookingStatus status) {
    return bookings.where((booking) => booking.status == status).length;
  }

  List<MapEntry<String, int>> _popularServices(List<Booking> bookings) {
    final counts = <String, int>{};

    for (final booking in bookings) {
      final serviceName = booking.serviceName.trim();

      if (serviceName.isEmpty) {
        continue;
      }

      counts[serviceName] = (counts[serviceName] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);

        if (byCount != 0) {
          return byCount;
        }

        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries.take(5).toList();
  }

  Widget _shopCard(BuildContext context, AppLocalizations loc) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.yourShop, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(shop.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(shop.address ?? loc.noAddress),
          const SizedBox(height: 4),
          Text(shop.phone ?? loc.noPhone),
        ],
      ),
    );
  }

  Widget _revenueCard(
    BuildContext context,
    AppLocalizations loc,
    double revenue,
  ) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.revenue,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${revenue.toStringAsFixed(2)} ${loc.currency}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularServicesCard(
    BuildContext context,
    AppLocalizations loc,
    List<MapEntry<String, int>> popularServices,
  ) {
    return AppCard(
      child: popularServices.isEmpty
          ? Text(loc.noBookingsYet)
          : Column(
              children: [
                for (
                  var index = 0;
                  index < popularServices.length;
                  index++
                ) ...[
                  if (index > 0) const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(child: Text(popularServices[index].key)),
                      Text(
                        loc.bookingsCount(popularServices[index].value),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ownerDashboard),
        actions: [
          IconButton(
            onPressed: () => _refresh(context),
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
          ),
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.settings,
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: loc.logout,
          ),
        ],
      ),
      body: BlocBuilder<BarberCubit, BarberState>(
        builder: (context, barberState) {
          return BlocBuilder<ServiceCubit, ServiceState>(
            builder: (context, serviceState) {
              return BlocBuilder<BookingCubit, BookingState>(
                builder: (context, bookingState) {
                  final isLoading =
                      barberState is BarberInitial ||
                      barberState is BarberLoading ||
                      serviceState is ServiceInitial ||
                      serviceState is ServiceLoading ||
                      bookingState is BookingInitial ||
                      bookingState is BookingLoading;

                  if (isLoading) {
                    return LoadingView(message: loc.loadingDashboard);
                  }

                  final errorMessage = _errorMessage(
                    barberState,
                    serviceState,
                    bookingState,
                  );

                  if (errorMessage != null) {
                    return ErrorView(
                      title: loc.dashboardLoadError,
                      message: errorMessage,
                      retryLabel: loc.retry,
                      onRetry: () => _refresh(context),
                    );
                  }

                  final barbers = barberState is BarberLoaded
                      ? barberState.barbers
                      : const <Barber>[];

                  final services = serviceState is ServiceLoaded
                      ? serviceState.services
                      : const <Service>[];

                  final bookings = bookingState is BookingLoaded
                      ? bookingState.bookings
                      : const <Booking>[];

                  final revenue = _revenue(bookings);

                  final popularServices = _popularServices(bookings);

                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _shopCard(context, loc),
                        const SizedBox(height: 12),
                        _revenueCard(context, loc, revenue),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            _OwnerMetricCard(
                              title: loc.totalBarbers,
                              value: '${barbers.length}',
                              icon: Icons.group_outlined,
                            ),
                            _OwnerMetricCard(
                              title: loc.totalServices,
                              value: '${services.length}',
                              icon: Icons.design_services_outlined,
                            ),
                            _OwnerMetricCard(
                              title: loc.pendingBookings,
                              value:
                                  '${_countByStatus(bookings, BookingStatus.pending)}',
                              icon: Icons.hourglass_empty,
                            ),
                            _OwnerMetricCard(
                              title: loc.completedBookings,
                              value:
                                  '${_countByStatus(bookings, BookingStatus.completed)}',
                              icon: Icons.check_circle_outline,
                            ),
                            _OwnerMetricCard(
                              title: loc.cancelledBookings,
                              value:
                                  '${_countByStatus(bookings, BookingStatus.cancelled)}',
                              icon: Icons.cancel_outlined,
                            ),
                            _OwnerMetricCard(
                              title: loc.noShow,
                              value:
                                  '${_countByStatus(bookings, BookingStatus.noShow)}',
                              icon: Icons.person_off_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.popularServices,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _popularServicesCard(context, loc, popularServices),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerMetricCard extends StatelessWidget {
  const _OwnerMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

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
import 'package:barber_booking/features/service/domain/entities/service.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_cubit.dart';
import 'package:barber_booking/features/service/presentation/cubit/service_state.dart';
import 'package:barber_booking/features/service/presentation/pages/customer_services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Header(
          customerName: widget.customerName,
          shopName: shop.name,
          loc: loc,
        ),
        const SizedBox(height: 12),
        _BookAppointmentAction(shop: shop, barber: _selectedBarber),
        const SizedBox(height: 16),
        _SectionHeader(title: loc.upcomingAppointment),
        const SizedBox(height: 10),
        upcomingBooking == null
            ? EmptyView(
                title: loc.noUpcomingAppointment,
                message: loc.nextBookingMessage,
                icon: Icons.event_available_outlined,
              )
            : _AppointmentCard(booking: upcomingBooking),
        const SizedBox(height: 28),
        _SectionHeader(title: loc.barberSelection),
        const SizedBox(height: 10),
        _BarberSectionContent(
          shop: shop,
          barbers: barbers,
          barberState: barberState,
          selectedBarber: _selectedBarber,
          onBarberSelected: _selectBarber,
          loc: loc,
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: loc.services),
        const SizedBox(height: 10),
        _ServiceSectionContent(
          services: services,
          serviceState: serviceState,
          shop: shop,
          loc: loc,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/auth/presentation/pages/barber_login_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/login_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/otp_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/register_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/splash_page.dart';
import 'package:barber_booking/features/booking/views/booking_details_page.dart';
import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';
import 'package:barber_booking/features/notifications/presentation/pages/notifications_page.dart';
import 'package:barber_booking/features/payment/presentation/pages/booking_payment_page.dart';
import 'package:barber_booking/features/payment/presentation/pages/payout_destination_page.dart';
import 'package:barber_booking/features/payment/presentation/pages/subscription_page.dart';

class AppRouter {
  AppRouter({required this._authCubit}) {
    router = GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(_authCubit.stream),
      redirect: _redirect,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) {
            return _authProvider(const SplashPage());
          },
        ),
        GoRoute(
          path: '/',
          builder: (context, state) {
            return _authProvider(const LoginPage());
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            return _authProvider(const LoginPage());
          },
        ),
        GoRoute(
          path: '/barber-login',
          builder: (context, state) {
            return _authProvider(const BarberLoginPage());
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            return _authProvider(const RegisterPage());
          },
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phoneNumber = state.uri.queryParameters['phone'] ?? '';

            return _authProvider(OtpPage(phoneNumber: phoneNumber));
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            return _authProvider(const DashboardPage());
          },
        ),
        GoRoute(
          path: '/payment/booking',
          builder: (context, state) {
            final bookingId = state.uri.queryParameters['bookingId'] ?? '';
            final shopId = state.uri.queryParameters['shopId'] ?? '';
            final total =
                int.tryParse(
                  state.uri.queryParameters['totalPiasters'] ?? '',
                ) ??
                0;

            return _authProvider(
              BookingPaymentPage(
                bookingId: bookingId,
                shopId: shopId,
                totalPiasters: total,
              ),
            );
          },
        ),
        GoRoute(
          path: '/payment/subscription',
          builder: (context, state) {
            final ownerId = state.uri.queryParameters['ownerId'] ?? '';

            return _authProvider(SubscriptionPage(ownerId: ownerId));
          },
        ),
        GoRoute(
          path: '/payment/payout-destination',
          builder: (context, state) {
            final ownerId = state.uri.queryParameters['ownerId'] ?? '';

            return _authProvider(PayoutDestinationPage(ownerId: ownerId));
          },
        ),
        // Booking-related notification taps land here with
        // `?bookingId=<id>`; other notifications land on `/notifications`.
        GoRoute(
          path: '/notifications',
          builder: (context, state) {
            final authState = _authCubit.state;

            final recipientId = authState is AuthAuthenticated
                ? authState.user.id
                : '';

            return _authProvider(NotificationsPage(recipientId: recipientId));
          },
        ),
        // Minimal booking-details destination for notification taps.
        // Reuses the existing booking repository/model; Firestore rules
        // decide which booking the signed-in user may read.
        GoRoute(
          path: '/booking-details',
          builder: (context, state) {
            final bookingId =
                state.uri.queryParameters['bookingId']?.trim() ?? '';

            return _authProvider(BookingDetailsPage(bookingId: bookingId));
          },
        ),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(child: Text('Page not found: ${state.uri}')),
        );
      },
    );
  }

  final AuthCubit _authCubit;

  late final GoRouter router;

  Widget _authProvider(Widget child) {
    return BlocProvider<AuthCubit>.value(value: _authCubit, child: child);
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = _authCubit.state;

    final isCheckingSession = authState is AuthCheckingSession;

    final isLoading = authState is AuthLoading;

    final isAuthenticated = authState is AuthAuthenticated;

    final isCodeSent = authState is AuthCodeSent;

    final location = state.matchedLocation;

    final isAuthRoute =
        location == '/' ||
        location == '/login' ||
        location == '/barber-login' ||
        location == '/register' ||
        location == '/otp';

    if (isCheckingSession) {
      if (location == '/splash') {
        return null;
      }

      return '/splash';
    }

    if (isAuthenticated) {
      if (isAuthRoute || location == '/splash') {
        return '/dashboard';
      }

      return null;
    }

    if (isCodeSent) {
      if (location == '/otp') {
        return null;
      }

      return '/otp?phone=${Uri.encodeComponent(authState.phoneNumber)}';
    }

    if (isLoading) {
      return null;
    }

    if (location == '/splash') {
      return '/login';
    }

    if (location == '/otp') {
      return '/login';
    }

    if (location == '/') {
      return '/login';
    }

    if (!isAuthRoute) {
      return '/login';
    }

    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

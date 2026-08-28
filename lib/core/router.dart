import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';
import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';
import 'package:barber_booking/features/auth/views/login_page.dart';
import 'package:barber_booking/features/auth/views/otp_page.dart';
import 'package:barber_booking/features/settings/views/settings_page.dart';
import 'package:barber_booking/features/booking/views/booking_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final loggedIn = authCubit.state is AuthAuthenticated;
        final authRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp';
        if (!loggedIn && !authRoute) return '/login';
        if (loggedIn && authRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (c, s) => const DashboardPage()),
        GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
        GoRoute(
          path: '/otp',
          builder: (c, s) {
            final phone = s.uri.queryParameters['phone'];
            return phone == null || phone.isEmpty
                ? const LoginPage()
                : OtpPage(phoneNumber: phone);
          },
        ),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
        GoRoute(path: '/booking', builder: (c, s) => const BookingPage()),
      ],
    );
  }
}

/// Helper to convert a Stream to a Listenable for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

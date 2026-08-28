import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/features/auth/auth_cubit.dart';
import 'package:barber_booking/features/auth/views/login_page.dart';
import 'package:barber_booking/features/auth/views/otp_page.dart';
import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final isAuthenticated = authCubit.state is AuthAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/otp';

        if (state.matchedLocation == '/' && isAuthenticated) {
          return '/dashboard';
        }
        if (state.matchedLocation == '/' && !isAuthenticated) {
          return '/login';
        }
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }
        if (isAuthenticated && state.matchedLocation == '/login') {
          return '/dashboard';
        }
        if (isAuthenticated && state.matchedLocation == '/otp') {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/otp',
          builder: (context, state) {
            final phoneNumber =
                state.uri.queryParameters['phone'] ?? authCubit.phoneNumber ?? '';
            return OtpPage(phoneNumber: phoneNumber);
          },
        ),
        GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
      ],
    );
  }
}

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

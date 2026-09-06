// // import 'dart:async';

// // import 'package:flutter/material.dart';
// // import 'package:go_router/go_router.dart';

// // import 'package:barber_booking/features/auth/auth_cubit.dart';
// // import 'package:barber_booking/features/auth/views/login_page.dart';
// // import 'package:barber_booking/features/auth/views/otp_page.dart';
// // import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';

// // class AppRouter {
// //   static GoRouter createRouter(AuthCubit authCubit) {
// //     return GoRouter(
// //       initialLocation: '/',
// //       debugLogDiagnostics: false,
// //       refreshListenable: GoRouterRefreshStream(authCubit.stream),
// //       redirect: (context, state) {
// //         final isAuthenticated = authCubit.state is AuthAuthenticated;
// //         final isAuthRoute =
// //             state.matchedLocation == '/login' ||
// //             state.matchedLocation == '/otp';

// //         if (state.matchedLocation == '/' && isAuthenticated) {
// //           return '/dashboard';
// //         }
// //         if (state.matchedLocation == '/' && !isAuthenticated) {
// //           return '/login';
// //         }
// //         if (!isAuthenticated && !isAuthRoute) {
// //           return '/login';
// //         }
// //         if (isAuthenticated && state.matchedLocation == '/login') {
// //           return '/dashboard';
// //         }
// //         if (isAuthenticated && state.matchedLocation == '/otp') {
// //           return '/dashboard';
// //         }
// //         // Guard against landing on /otp directly (typed URL, refresh, back
// //         // button, deep link) without a phone number to verify. Without this,
// //         // OtpPage renders with an empty phone number and any resend/verify
// //         // call would be sent to Firebase with an empty string.
// //         if (!isAuthenticated && state.matchedLocation == '/otp') {
// //           final phone = state.uri.queryParameters['phone'];
// //           if (phone == null || phone.trim().isEmpty) {
// //             return '/login';
// //           }
// //         }
// //         return null;
// //       },
// //       routes: [
// //         GoRoute(path: '/', builder: (context, state) => const LoginPage()),
// //         GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
// //         GoRoute(
// //           path: '/otp',
// //           builder: (context, state) {
// //             final phoneNumber = state.uri.queryParameters['phone'] ?? '';
// //             return OtpPage(phoneNumber: phoneNumber);
// //           },
// //         ),
// //         GoRoute(
// //           path: '/dashboard',
// //           builder: (context, state) => const DashboardPage(),
// //         ),
// //       ],
// //       errorBuilder: (context, state) =>
// //           Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
// //     );
// //   }
// // }

// // class GoRouterRefreshStream extends ChangeNotifier {
// //   GoRouterRefreshStream(Stream<dynamic> stream) {
// //     _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
// //   }

// //   late final StreamSubscription<dynamic> _sub;

// //   @override
// //   void dispose() {
// //     _sub.cancel();
// //     super.dispose();
// //   }
// // }

// import 'dart:async';

// import 'package:barber_booking/features/settings/settings_cubit.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

// import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';

// import '../features/auth/views/login_page.dart';
// import '../features/auth/views/otp_page.dart';

// class AppRouter {
//   AppRouter({required this._authCubit, required SettingsCubit settingsCubit}) {
//     router = GoRouter(
//       initialLocation: '/',
//       debugLogDiagnostics: false,
//       refreshListenable: GoRouterRefreshStream(_authCubit.stream),
//       redirect: _redirect,
//       routes: [
//         GoRoute(path: '/', builder: (context, state) => const LoginPage()),
//         GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
//         GoRoute(
//           path: '/otp',
//           builder: (context, state) {
//             final phoneNumber = state.uri.queryParameters['phone'] ?? '';

//             return OtpPage(phoneNumber: phoneNumber);
//           },
//         ),
//         GoRoute(
//           path: '/dashboard',
//           builder: (context, state) => const DashboardPage(),
//         ),
//       ],
//       errorBuilder: (context, state) {
//         return Scaffold(
//           body: Center(child: Text('Page not found: ${state.uri}')),
//         );
//       },
//     );
//   }

//   final AuthCubit _authCubit;

//   late final GoRouter router;

//   String? _redirect(BuildContext context, GoRouterState state) {
//     final authState = _authCubit.state;

//     final isAuthenticated = authState is AuthAuthenticated;
//     final isLoading = authState is AuthLoading;
//     final isCodeSent = authState is AuthCodeSent;

//     final location = state.matchedLocation;

//     final isAuthRoute =
//         location == '/login' || location == '/otp' || location == '/';

//     // Don't redirect while an authentication operation is running.
//     if (isLoading) {
//       return null;
//     }

//     // Authenticated user.
//     if (isAuthenticated) {
//       if (isAuthRoute) {
//         return '/dashboard';
//       }

//       return null;
//     }

//     // OTP flow is active.
//     if (isCodeSent) {
//       if (location == '/otp') {
//         return null;
//       }

//       return '/otp?phone=${Uri.encodeComponent(isCodeSent ? authState.phoneNumber : '')}';
//     }

//     // Unauthenticated user.
//     if (location == '/') {
//       return '/login';
//     }

//     if (location == '/otp') {
//       final phone = state.uri.queryParameters['phone'];

//       if (phone == null || phone.trim().isEmpty) {
//         return '/login';
//       }

//       return null;
//     }

//     if (!isAuthRoute && location != '/login') {
//       return '/login';
//     }

//     return null;
//   }
// }

// class GoRouterRefreshStream extends ChangeNotifier {
//   GoRouterRefreshStream(Stream<dynamic> stream) {
//     _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
//   }

//   late final StreamSubscription<dynamic> _subscription;

//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/auth/presentation/pages/login_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/otp_page.dart';
import 'package:barber_booking/features/dashboard/views/dashboard_page.dart';
import 'package:barber_booking/features/auth/presentation/pages/register_page.dart';

class AppRouter {
  AppRouter({required this._authCubit}) {
    router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(_authCubit.stream),
      redirect: _redirect,
      routes: [
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
          path: '/register',
          builder: (context, state) {
            return _authProvider(const RegisterPage());
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

    final isAuthenticated = authState is AuthAuthenticated;
    final isLoading = authState is AuthLoading;
    final isCodeSent = authState is AuthCodeSent;

    final location = state.matchedLocation;

    final isAuthRoute =
        location == '/' ||
        location == '/login' ||
        location == '/register' ||
        location == '/otp';

    // Keep the current route while an authentication
    // operation is in progress.
    if (isLoading) {
      return null;
    }

    // Authenticated user.
    if (isAuthenticated) {
      if (isAuthRoute) {
        return '/dashboard';
      }

      return null;
    }

    // OTP flow.
    if (isCodeSent) {
      if (location == '/otp') {
        return null;
      }

      return '/otp?phone=${Uri.encodeComponent(authState.phoneNumber)}';
    }

    // Unauthenticated user trying to access OTP.
    if (location == '/otp') {
      if (!isCodeSent) {
        return '/login';
      }

      return null;
    }
    // Root goes to login.
    if (location == '/') {
      return '/login';
    }

    // Protect application routes.
    if (!isAuthRoute) {
      return '/login';
    }

    return null;
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

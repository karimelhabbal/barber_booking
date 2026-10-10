import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/router.dart';
import 'package:barber_booking/core/services/supabase_service.dart';
import 'package:barber_booking/core/theme/app_theme.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:barber_booking/features/notifications/services/notification_service.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';
import 'package:barber_booking/firebase_options.dart';

/// Application entry point.
///
/// Initialization order:
/// 1. Flutter binding + wakelock.
/// 2. Supabase (auth, database and notification queue backend). Configure with
///    `--dart-define=SUPABASE_URL=...` (optional) and
///    `--dart-define=SUPABASE_ANON_KEY=<publishable/anon key>`.
/// 3. Firebase core only. It is still required by Firebase Cloud Messaging
///    (push delivery) and the payment data source. Firebase Auth/Firestore are
///    not used for sign-in or app data and are not configured here.
/// 4. Dependency injection (`configureDependencies`).
/// 5. Persisted settings (locale / theme mode).
/// 6. `runApp`. `AuthCubit` restores the Supabase session, and `AppRouter`
///    attaches the router to `NotificationService` and initializes it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await WakelockPlus.enable();
  } on Object catch (error) {
    debugPrint('Wakelock enable failed: $error');
  }

  await SupabaseService.initialize();

  // FCM (and the payment data source) need the default Firebase app. A failure
  // here must not prevent the Supabase-backed app from starting.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }

  configureDependencies();

  final settingsCubit = SettingsCubit();
  await settingsCubit.loadSettings();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settingsCubit),
        BlocProvider<NotificationsCubit>.value(
          value: getIt<NotificationsCubit>(),
        ),
      ],
      child: MyApp(settingsCubit: settingsCubit),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsCubit});

  final SettingsCubit settingsCubit;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthCubit _authCubit;
  late final AppRouter _appRouter;
  late final NotificationService _notificationService;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authCubit = getIt<AuthCubit>();

    // Also attaches the router to NotificationService and initializes it.
    _appRouter = AppRouter(authCubit: _authCubit);

    _notificationService = getIt<NotificationService>();

    // A cold-start notification tap is kept pending until the session is
    // restored, then consumed here (never during the splash redirect).
    _authSubscription = _authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _notificationService.tryConsumePendingTap();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authCubit.close();
    widget.settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: widget.settingsCubit,
      builder: (context, settingsState) {
        return BlocProvider<AuthCubit>.value(
          value: _authCubit,
          child: MaterialApp.router(
            title: 'Barber Booking',
            routerConfig: _appRouter.router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            locale: settingsState.locale,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settingsState.themeMode,
          ),
        );
      },
    );
  }
}

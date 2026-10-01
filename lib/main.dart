import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/router.dart';
import 'package:barber_booking/core/services/firebase_service.dart';
import 'package:barber_booking/core/theme/app_theme.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:barber_booking/features/notifications/services/notification_service.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();

  await FirebaseService.initFirebase();

  // Registered before the app starts so terminated-state messages are handled
  // by the OS and delivered to this isolate where needed.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } on Object catch (error) {
    debugPrint('FCM background handler registration failed: $error');
  }

  configureDependencies();

  // Prepares local notifications, FCM listeners and push permission.
  // Never blocks app startup: unsupported platforms simply disable pushes.
  try {
    await getIt<NotificationService>().initialize();
  } on Object catch (error) {
    debugPrint('NotificationService initialization failed: $error');
  }

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

  @override
  void initState() {
    super.initState();

    _authCubit = getIt<AuthCubit>();

    _appRouter = AppRouter(authCubit: _authCubit);

    // Lets notification taps navigate through the real GoRouter.
    _notificationService = getIt<NotificationService>();
    _notificationService.attachRouter(_appRouter.router);

    // A cold-start tap is kept pending until the session is restored, then
    // consumed here (never during the splash redirect).
    _authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _notificationService.tryConsumePendingTap();
      }
    });
  }

  @override
  void dispose() {
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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:barber_booking/core/di/injection.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/router.dart';
import 'package:barber_booking/core/services/firebase_service.dart';
import 'package:barber_booking/core/theme/app_theme.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();

  await FirebaseService.initFirebase();

  configureDependencies();

  final settingsCubit = SettingsCubit();
  await settingsCubit.loadSettings();

  runApp(
    BlocProvider<SettingsCubit>.value(
      value: settingsCubit,
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

  @override
  void initState() {
    super.initState();

    _authCubit = getIt<AuthCubit>();

    _appRouter = AppRouter(authCubit: _authCubit);
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
        return MaterialApp.router(
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
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/services/firebase_service.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';
import 'package:barber_booking/features/settings/settings_cubit.dart';
import 'package:barber_booking/core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initFirebase();
  final authCubit = AuthCubit();
  final settingsCubit = SettingsCubit();
  await settingsCubit.loadSettings();

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<SettingsCubit>.value(value: settingsCubit),
    ],
    child: MyApp(authCubit: authCubit, settingsCubit: settingsCubit),
  ));
}

class MyApp extends StatelessWidget {
  final AuthCubit authCubit;
  final SettingsCubit settingsCubit;
  const MyApp({super.key, required this.authCubit, required this.settingsCubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      bloc: settingsCubit,
      builder: (context, settingsState) {
        final router = AppRouter.createRouter(authCubit);
        return MaterialApp.router(
          title: 'Barber Booking',
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: settingsState.locale,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsState.themeMode,
        );
      },
    );
  }
}

part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final Locale locale;
  final ThemeMode themeMode;
  const SettingsState({required this.locale, required this.themeMode});

  @override
  List<Object?> get props => [locale, themeMode];
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  static const _localeKey = 'locale';
  static const _themeModeKey = 'themeMode';

  SettingsCubit() : super(SettingsState(locale: const Locale('en'), themeMode: ThemeMode.system));

  Future<void> loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    final localeCode = sp.getString(_localeKey) ?? 'en';
    final themeIndex = sp.getInt(_themeModeKey);
    ThemeMode themeMode = ThemeMode.system;
    if (themeIndex != null) {
      themeMode = ThemeMode.values[themeIndex];
    }
    emit(SettingsState(locale: Locale(localeCode), themeMode: themeMode));
  }

  Future<void> changeLanguage(String code) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_localeKey, code);
    emit(SettingsState(locale: Locale(code), themeMode: state.themeMode));
  }

  Future<void> toggleTheme() async {
    final sp = await SharedPreferences.getInstance();
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await sp.setInt(_themeModeKey, ThemeMode.values.indexOf(next));
    emit(SettingsState(locale: state.locale, themeMode: next));
  }
}

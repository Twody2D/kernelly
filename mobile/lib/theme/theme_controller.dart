import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/user_prefs.dart';

/// Живое переключение темы без рестарта: MaterialApp в main.dart слушает
/// [themeController] через ValueListenableBuilder, а settings_courses_screen.dart
/// дёргает [ThemeController.setTheme] сразу после сохранения тумблера в prefs.
/// Пакетов состояния в проекте ещё нет, поэтому обходимся ValueNotifier.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static ThemeMode _modeFromPref(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    value = _modeFromPref(prefs.getString(PrefKeys.theme));
  }

  /// [pref] — 'light' / 'dark' / 'auto', как хранится в SharedPreferences.
  void setTheme(String pref) {
    value = _modeFromPref(pref == 'auto' ? null : pref);
  }
}

final themeController = ThemeController();

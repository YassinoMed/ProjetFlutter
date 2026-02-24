/// Theme Provider - Manages dark/light mode
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(AppConstants.keyThemeMode);
    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  Future<void> toggleTheme() async {
    final newMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

// ── Provider ────────────────────────────────────────────────

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

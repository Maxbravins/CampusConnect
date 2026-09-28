import 'package:flutter/material.dart';
import 'storage_service.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Call once at app startup (before runApp) to restore the saved theme.
  static Future<void> init() async {
    final saved = await StorageService.getThemeMode();
    if (saved == "dark") {
      themeMode.value = ThemeMode.dark;
    } else if (saved == "light") {
      themeMode.value = ThemeMode.light;
    }
    // If nothing saved yet, keep the default (light) and don't write anything.
  }

  static void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    StorageService.saveThemeMode(themeMode.value == ThemeMode.dark ? "dark" : "light");
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;
}
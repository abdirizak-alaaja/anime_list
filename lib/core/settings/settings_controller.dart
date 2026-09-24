import 'package:flutter/material.dart';

import '../storage/key_value_store.dart';

/// App-level user preferences. Dark mode is the default.
class SettingsController extends ChangeNotifier {
  SettingsController(this._store)
    : _themeMode = _parseThemeMode(_store.getString(_themeModeKey));

  static const _themeModeKey = 'settings.theme_mode';

  final KeyValueStore _store;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _store.setString(_themeModeKey, mode.name);
  }

  static ThemeMode _parseThemeMode(String? value) => ThemeMode.values
      .firstWhere((mode) => mode.name == value, orElse: () => ThemeMode.dark);
}

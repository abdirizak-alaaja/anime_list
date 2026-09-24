import 'package:anime_list/core/settings/settings_controller.dart';
import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to dark and persists the choice', () async {
    final store = InMemoryKeyValueStore();
    final settings = SettingsController(store);
    expect(settings.themeMode, ThemeMode.dark);

    await settings.setThemeMode(ThemeMode.light);
    expect(SettingsController(store).themeMode, ThemeMode.light);
  });

  test('ignores unknown stored values', () {
    final store = InMemoryKeyValueStore({'settings.theme_mode': 'purple'});
    expect(SettingsController(store).themeMode, ThemeMode.dark);
  });
}

import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';

/// App bar action that switches between dark, light and system themes.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final mode = settings.themeMode;
        return PopupMenuButton<ThemeMode>(
          tooltip: 'Theme',
          initialValue: mode,
          icon: Icon(switch (mode) {
            ThemeMode.dark => Icons.dark_mode_outlined,
            ThemeMode.light => Icons.light_mode_outlined,
            ThemeMode.system => Icons.brightness_auto_outlined,
          }),
          onSelected: settings.setThemeMode,
          itemBuilder: (context) => const [
            PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
            PopupMenuItem(value: ThemeMode.system, child: Text('System')),
          ],
        );
      },
    );
  }
}

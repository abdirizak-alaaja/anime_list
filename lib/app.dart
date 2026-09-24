import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'core/navigation/app_shell.dart';
import 'core/theme/app_theme.dart';

class AnimeListApp extends StatelessWidget {
  const AnimeListApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final settings = dependencies.settings;

    return AppScope(
      dependencies: dependencies,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          // Honor the system text size, but cap it where fixed-height
          // layouts (carousels, cards) would stop being usable.
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 2,
            child: child!,
          ),
          home: const AppShell(),
        ),
      ),
    );
  }
}

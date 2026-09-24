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
          home: const AppShell(),
        ),
      ),
    );
  }
}

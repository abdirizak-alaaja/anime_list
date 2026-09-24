import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

/// Exposes [AppDependencies] to the widget tree.
///
/// The dependencies are fixed for the app's lifetime, so looking them up
/// doesn't register a rebuild dependency.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

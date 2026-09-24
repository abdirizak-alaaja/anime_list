import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/storage/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final dependencies = AppDependencies(
    store: SharedPreferencesKeyValueStore(prefs),
  );

  runApp(AnimeListApp(dependencies: dependencies));
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/network/jikan_http_client.dart';
import 'core/network/saved_responses.dart';
import 'core/storage/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final (prefs, savedResponses) = await (
    SharedPreferences.getInstance(),
    openSavedResponseStore(),
  ).wait;
  final dependencies = AppDependencies(
    store: SharedPreferencesKeyValueStore(prefs),
    httpClient: JikanHttpClient(savedResponses: savedResponses),
  );

  runApp(AnimeListApp(dependencies: dependencies));
}

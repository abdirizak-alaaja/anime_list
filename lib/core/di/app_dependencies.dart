import '../network/jikan_api.dart';
import '../network/jikan_http_client.dart';
import '../settings/settings_controller.dart';
import '../storage/key_value_store.dart';

/// Long-lived services shared across the app.
///
/// Built once at startup in `main.dart`, and replaced with fakes in tests.
class AppDependencies {
  AppDependencies({required this.store, JikanHttpClient? httpClient})
    : settings = SettingsController(store),
      _httpClient = httpClient ?? JikanHttpClient() {
    jikan = JikanApi(_httpClient);
  }

  final KeyValueStore store;
  final SettingsController settings;
  final JikanHttpClient _httpClient;
  late final JikanApi jikan;

  void dispose() {
    settings.dispose();
    _httpClient.close();
  }
}

import '../settings/settings_controller.dart';
import '../storage/key_value_store.dart';

/// Long-lived services shared across the app.
///
/// Built once at startup in `main.dart`, and replaced with fakes in tests.
class AppDependencies {
  AppDependencies({required this.store}) : settings = SettingsController(store);

  final KeyValueStore store;
  final SettingsController settings;

  void dispose() {
    settings.dispose();
  }
}

import '../../features/favorites/data/favorites_storage.dart';
import '../../features/favorites/repositories/favorites_repository.dart';
import '../../features/library/data/library_storage.dart';
import '../../features/library/repositories/library_repository.dart';
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
      library = LibraryRepository(LibraryStorage(store)),
      favorites = FavoritesRepository(FavoritesStorage(store)),
      _httpClient = httpClient ?? JikanHttpClient() {
    jikan = JikanApi(_httpClient);
  }

  final KeyValueStore store;
  final SettingsController settings;
  final LibraryRepository library;
  final FavoritesRepository favorites;
  final JikanHttpClient _httpClient;
  late final JikanApi jikan;

  void dispose() {
    settings.dispose();
    library.dispose();
    favorites.dispose();
    _httpClient.close();
  }
}

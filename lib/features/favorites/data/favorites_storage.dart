import '../../../core/storage/key_value_store.dart';
import '../../../core/utils/json.dart';
import '../models/favorite_entry.dart';

/// Reads and writes favorites as a JSON list.
class FavoritesStorage {
  const FavoritesStorage(this._store);

  static const _key = 'favorites.entries.v1';

  final KeyValueStore _store;

  List<FavoriteEntry> load() {
    final json = _store.readJson(_key);
    if (json is! List) return const [];
    return [
      for (final item in json)
        if (asJson(item) case final map?) ?FavoriteEntry.fromJson(map),
    ];
  }

  Future<void> save(Iterable<FavoriteEntry> entries) =>
      _store.writeJson(_key, [for (final e in entries) e.toJson()]);
}

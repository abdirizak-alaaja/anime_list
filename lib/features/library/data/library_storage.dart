import '../../../core/storage/key_value_store.dart';
import '../../../core/utils/json.dart';
import '../models/library_entry.dart';

/// Reads and writes library entries as a JSON list.
class LibraryStorage {
  const LibraryStorage(this._store);

  static const _key = 'library.entries.v1';

  final KeyValueStore _store;

  List<LibraryEntry> load() {
    final json = _store.readJson(_key);
    if (json is! List) return const [];
    return [
      for (final item in json)
        if (asJson(item) case final map?) ?LibraryEntry.fromJson(map),
    ];
  }

  Future<void> save(Iterable<LibraryEntry> entries) =>
      _store.writeJson(_key, [for (final e in entries) e.toJson()]);
}

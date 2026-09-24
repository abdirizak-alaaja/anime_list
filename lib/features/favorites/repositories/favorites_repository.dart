import 'package:flutter/foundation.dart';

import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_snapshot.dart';
import '../data/favorites_storage.dart';
import '../models/favorite_entry.dart';

/// The user's favorite anime, persisted locally and available offline.
///
/// Independent of the library: an anime can be a favorite without being
/// on the user's list.
class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    for (final entry in _storage.load()) {
      _entries[entry.malId] = entry;
    }
  }

  final FavoritesStorage _storage;
  final DateTime Function() _now;
  final Map<int, FavoriteEntry> _entries = {};

  /// All favorites, most recently added first.
  List<FavoriteEntry> get entries =>
      _entries.values.toList()..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  int get count => _entries.length;

  bool isFavorite(int malId) => _entries.containsKey(malId);

  Future<void> add(Anime anime) => _restore(
    FavoriteEntry(anime: AnimeSnapshot.fromAnime(anime), addedAt: _now()),
  );

  /// Removes a favorite and returns it, so it can be restored (undo).
  Future<FavoriteEntry?> remove(int malId) async {
    final removed = _entries.remove(malId);
    if (removed == null) return null;
    notifyListeners();
    await _persist();
    return removed;
  }

  /// Returns whether the anime is a favorite after toggling.
  Future<bool> toggle(Anime anime) async {
    if (isFavorite(anime.malId)) {
      await remove(anime.malId);
      return false;
    }
    await add(anime);
    return true;
  }

  /// Re-inserts a previously removed entry, keeping its original date.
  Future<void> restore(FavoriteEntry entry) => _restore(entry);

  /// Refreshes the stored metadata from newly fetched API data.
  Future<void> syncMetadata(Anime anime) async {
    final entry = _entries[anime.malId];
    if (entry == null) return;
    await _restore(
      FavoriteEntry(
        anime: entry.anime.mergeWith(anime),
        addedAt: entry.addedAt,
      ),
    );
  }

  Future<void> _restore(FavoriteEntry entry) async {
    _entries[entry.malId] = entry;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _storage.save(_entries.values);
}

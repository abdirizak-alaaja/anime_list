import 'package:flutter/foundation.dart';

import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_snapshot.dart';
import '../data/library_storage.dart';
import '../models/library_entry.dart';
import '../models/watch_status.dart';

/// The user's anime list, persisted locally and available offline.
///
/// Status and progress follow MyAnimeList's conventions:
/// - marking Completed fills in all episodes (when the total is known);
/// - watching the final episode marks the entry Completed;
/// - logging an episode on a Plan to Watch entry starts watching it.
class LibraryRepository extends ChangeNotifier {
  LibraryRepository(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    for (final entry in _storage.load()) {
      _entries[entry.malId] = entry;
    }
  }

  final LibraryStorage _storage;
  final DateTime Function() _now;
  final Map<int, LibraryEntry> _entries = {};

  /// All entries, most recently updated first.
  List<LibraryEntry> get entries =>
      _entries.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  LibraryEntry? entryFor(int malId) => _entries[malId];

  bool contains(int malId) => _entries.containsKey(malId);

  int countFor(WatchStatus status) =>
      _entries.values.where((e) => e.status == status).length;

  Future<void> add(
    Anime anime, {
    WatchStatus status = WatchStatus.planToWatch,
  }) {
    final existing = _entries[anime.malId];
    if (existing != null) return setStatus(anime.malId, status);

    final now = _now();
    final snapshot = AnimeSnapshot.fromAnime(anime);
    return _put(
      _applyStatus(
        LibraryEntry(
          anime: snapshot,
          status: status,
          episodesWatched: 0,
          addedAt: now,
          updatedAt: now,
        ),
        status,
      ),
    );
  }

  Future<void> remove(int malId) async {
    if (_entries.remove(malId) == null) return;
    notifyListeners();
    await _persist();
  }

  /// Re-inserts a previously removed entry unchanged (undo).
  Future<void> restore(LibraryEntry entry) => _put(entry);

  Future<void> setStatus(int malId, WatchStatus status) async {
    final entry = _entries[malId];
    if (entry == null || entry.status == status) return;
    await _put(_applyStatus(entry, status));
  }

  /// Sets the watched episode count, clamped to the known total.
  Future<void> setEpisodesWatched(int malId, int episodes) async {
    final entry = _entries[malId];
    if (entry == null) return;

    final total = entry.totalEpisodes;
    final clamped = total == null
        ? episodes.clamp(0, 100000)
        : episodes.clamp(0, total);
    if (clamped == entry.episodesWatched) return;

    var status = entry.status;
    if (total != null && total > 0 && clamped == total) {
      status = WatchStatus.completed;
    } else if (clamped > 0 && status == WatchStatus.planToWatch) {
      status = WatchStatus.watching;
    } else if (status == WatchStatus.completed && clamped < (total ?? 0)) {
      status = WatchStatus.watching;
    }

    await _put(
      entry.copyWith(
        episodesWatched: clamped,
        status: status,
        updatedAt: _now(),
      ),
    );
  }

  Future<void> incrementEpisodes(int malId) async {
    final entry = _entries[malId];
    if (entry == null) return;
    await setEpisodesWatched(malId, entry.episodesWatched + 1);
  }

  Future<void> decrementEpisodes(int malId) async {
    final entry = _entries[malId];
    if (entry == null) return;
    await setEpisodesWatched(malId, entry.episodesWatched - 1);
  }

  /// Refreshes the stored metadata (episode count, status, poster...) from
  /// newly fetched API data. Doesn't change the entry's ordering.
  Future<void> syncMetadata(Anime anime) async {
    final entry = _entries[anime.malId];
    if (entry == null) return;
    await _put(entry.copyWith(anime: entry.anime.mergeWith(anime)));
  }

  LibraryEntry _applyStatus(LibraryEntry entry, WatchStatus status) {
    final total = entry.totalEpisodes;
    return entry.copyWith(
      status: status,
      episodesWatched: status == WatchStatus.completed && total != null
          ? total
          : entry.episodesWatched,
      updatedAt: _now(),
    );
  }

  Future<void> _put(LibraryEntry entry) async {
    _entries[entry.malId] = entry;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _storage.save(_entries.values);
}

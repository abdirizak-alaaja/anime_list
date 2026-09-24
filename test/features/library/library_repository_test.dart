import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/features/library/data/library_storage.dart';
import 'package:anime_list/features/library/models/watch_status.dart';
import 'package:anime_list/features/library/repositories/library_repository.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frieren = Anime(
    malId: 52991,
    title: 'Sousou no Frieren',
    episodes: 28,
    score: 9.3,
  );
  const onePiece = Anime(malId: 21, title: 'One Piece');

  late InMemoryKeyValueStore store;
  late LibraryRepository library;
  var clock = DateTime(2024);

  LibraryRepository open() => LibraryRepository(
    LibraryStorage(store),
    now: () => clock = clock.add(const Duration(minutes: 1)),
  );

  setUp(() {
    store = InMemoryKeyValueStore();
    library = open();
  });

  test('adds, updates and removes entries', () async {
    await library.add(frieren, status: WatchStatus.watching);
    expect(library.contains(frieren.malId), isTrue);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.watching);

    await library.setStatus(frieren.malId, WatchStatus.onHold);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.onHold);

    await library.remove(frieren.malId);
    expect(library.contains(frieren.malId), isFalse);
  });

  test('persists across restarts', () async {
    await library.add(frieren, status: WatchStatus.watching);
    await library.setEpisodesWatched(frieren.malId, 5);

    final reopened = open();
    final entry = reopened.entryFor(frieren.malId)!;
    expect(entry.status, WatchStatus.watching);
    expect(entry.episodesWatched, 5);
    expect(entry.anime.title, 'Sousou no Frieren');
    expect(entry.anime.score, 9.3);
  });

  test('clamps progress to the known episode count', () async {
    await library.add(frieren, status: WatchStatus.watching);
    await library.setEpisodesWatched(frieren.malId, 99);
    expect(library.entryFor(frieren.malId)?.episodesWatched, 28);

    await library.setEpisodesWatched(frieren.malId, -3);
    expect(library.entryFor(frieren.malId)?.episodesWatched, 0);
  });

  test('allows any progress when the total is unknown', () async {
    await library.add(onePiece, status: WatchStatus.watching);
    await library.setEpisodesWatched(onePiece.malId, 1100);
    final entry = library.entryFor(onePiece.malId)!;
    expect(entry.episodesWatched, 1100);
    expect(entry.progress, isNull);
    expect(entry.status, WatchStatus.watching);
  });

  test('follows MyAnimeList status conventions', () async {
    await library.add(frieren);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.planToWatch);

    await library.incrementEpisodes(frieren.malId);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.watching);

    await library.setEpisodesWatched(frieren.malId, 28);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.completed);

    await library.decrementEpisodes(frieren.malId);
    expect(library.entryFor(frieren.malId)?.status, WatchStatus.watching);

    await library.setStatus(frieren.malId, WatchStatus.completed);
    expect(library.entryFor(frieren.malId)?.episodesWatched, 28);
    expect(library.entryFor(frieren.malId)?.progress, 1);
  });

  test('lists most recently updated first', () async {
    await library.add(frieren);
    await library.add(onePiece);
    expect(library.entries.map((e) => e.malId), [21, 52991]);

    await library.incrementEpisodes(frieren.malId);
    expect(library.entries.map((e) => e.malId), [52991, 21]);
    expect(library.countFor(WatchStatus.watching), 1);
  });

  test('syncs metadata without losing stored fields', () async {
    await library.add(onePiece, status: WatchStatus.watching);
    await library.syncMetadata(
      const Anime(malId: 21, title: 'One Piece', episodes: 1122),
    );
    final entry = library.entryFor(21)!;
    expect(entry.totalEpisodes, 1122);
    expect(entry.status, WatchStatus.watching);
  });

  test('ignores corrupt stored data', () {
    store = InMemoryKeyValueStore({
      'library.entries.v1':
          '[{"anime": {"mal_id": 1, "title": "Ok"}, "status": "watching"},'
          ' {"anime": null}, 42, {"status": "bogus", '
          '"anime": {"mal_id": 2, "title": "Two"}}]',
    });
    final reopened = open();
    expect(reopened.entries.length, 2);
    expect(reopened.entryFor(2)?.status, WatchStatus.planToWatch);

    store = InMemoryKeyValueStore({'library.entries.v1': 'not json'});
    expect(open().entries, isEmpty);
  });
}

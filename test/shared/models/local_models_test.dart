import 'dart:convert';

import 'package:anime_list/features/library/models/library_entry.dart';
import 'package:anime_list/features/library/models/watch_status.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:anime_list/shared/models/anime_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const anime = Anime(
    malId: 52991,
    title: 'Sousou no Frieren',
    titleJapanese: '葬送のフリーレン',
    imageUrl: 'https://img/1.jpg',
    type: 'TV',
    episodes: 28,
    score: 9.3,
    status: 'Finished Airing',
    season: AnimeSeason.fall,
    year: 2023,
  );

  test('snapshot survives a JSON round trip', () {
    final snapshot = AnimeSnapshot.fromAnime(anime);
    final decoded = AnimeSnapshot.fromJson(
      jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>,
    )!;
    expect(decoded.title, anime.title);
    expect(decoded.titleJapanese, anime.titleJapanese);
    expect(decoded.episodes, 28);
    expect(decoded.score, 9.3);
    expect(decoded.season, AnimeSeason.fall);
    expect(decoded.toAnime().malId, anime.malId);
  });

  test('merging keeps stored values the API left out', () {
    final snapshot = AnimeSnapshot.fromAnime(anime);
    final merged = snapshot.mergeWith(
      const Anime(malId: 52991, title: 'Frieren', score: 9.4),
    );
    expect(merged.title, 'Frieren');
    expect(merged.score, 9.4);
    expect(merged.episodes, 28);
    expect(merged.imageUrl, 'https://img/1.jpg');
  });

  test('library entry round trip and progress', () {
    final entry = LibraryEntry(
      anime: AnimeSnapshot.fromAnime(anime),
      status: WatchStatus.onHold,
      episodesWatched: 7,
      addedAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 2, 1),
    );
    final decoded = LibraryEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    )!;
    expect(decoded.status, WatchStatus.onHold);
    expect(decoded.episodesWatched, 7);
    expect(decoded.updatedAt, DateTime.utc(2024, 2, 1));
    expect(decoded.progress, closeTo(0.25, 0.001));
  });

  test('status storage keys are stable', () {
    // Persisted data depends on these values; changing them loses data.
    expect(WatchStatus.values.map((s) => s.storageKey), [
      'watching',
      'completed',
      'on_hold',
      'dropped',
      'plan_to_watch',
    ]);
  });

  test('derives season and year from the air date when missing', () {
    final movie = Anime(
      malId: 1,
      title: 'Movie',
      airedFrom: DateTime(2016, 8, 26),
    );
    expect(movie.startYear, 2016);
    expect(movie.startSeason, AnimeSeason.summer);
  });
}

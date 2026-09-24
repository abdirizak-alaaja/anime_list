import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/features/favorites/data/favorites_storage.dart';
import 'package:anime_list/features/favorites/repositories/favorites_repository.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = Anime(malId: 1, title: 'Cowboy Bebop', score: 8.8);
  const b = Anime(malId: 5, title: 'Cowboy Bebop: The Movie');

  late InMemoryKeyValueStore store;
  var clock = DateTime(2024);

  FavoritesRepository open() => FavoritesRepository(
    FavoritesStorage(store),
    now: () => clock = clock.add(const Duration(minutes: 1)),
  );

  setUp(() => store = InMemoryKeyValueStore());

  test('toggles favorites', () async {
    final favorites = open();
    expect(await favorites.toggle(a), isTrue);
    expect(favorites.isFavorite(1), isTrue);
    expect(await favorites.toggle(a), isFalse);
    expect(favorites.isFavorite(1), isFalse);
  });

  test('persists across restarts, newest first', () async {
    final favorites = open();
    await favorites.add(a);
    await favorites.add(b);

    final reopened = open();
    expect(reopened.entries.map((e) => e.malId), [5, 1]);
    expect(reopened.entries.last.anime.score, 8.8);
  });

  test('remove can be undone with the original date', () async {
    final favorites = open();
    await favorites.add(a);
    await favorites.add(b);
    final removed = await favorites.remove(1);
    expect(favorites.count, 1);

    await favorites.restore(removed!);
    expect(favorites.entries.map((e) => e.malId), [5, 1]);
    expect(await favorites.remove(99), isNull);
  });

  test('notifies listeners on change', () async {
    final favorites = open();
    var notified = 0;
    favorites.addListener(() => notified++);
    await favorites.add(a);
    await favorites.remove(1);
    expect(notified, 2);
  });
}

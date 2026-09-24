import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/features/search/controllers/anime_search_controller.dart';
import 'package:anime_list/features/search/data/recent_searches_store.dart';
import 'package:anime_list/features/search/repositories/search_repository.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:anime_list/shared/models/anime_query.dart';
import 'package:anime_list/shared/models/paginated.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearchRepository implements SearchRepository {
  final queries = <String?>[];

  @override
  Future<Paginated<Anime>> search(
    AnimeQuery query, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    queries.add(query.text);
    return Paginated(
      items: [Anime(malId: page, title: '${query.text} $page')],
      currentPage: page,
      hasNextPage: false,
    );
  }
}

void main() {
  const debounce = Duration(milliseconds: 20);
  late _FakeSearchRepository repository;
  late AnimeSearchController controller;

  setUp(() {
    repository = _FakeSearchRepository();
    controller = AnimeSearchController(
      repository: repository,
      recentSearches: RecentSearchesStore(InMemoryKeyValueStore()),
      debounce: debounce,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> settle() => Future.delayed(debounce * 3);

  test('debounces typing into a single request', () async {
    for (final text in ['nar', 'naru', 'narut', 'naruto']) {
      controller.onQueryChanged(text);
    }
    await settle();
    expect(repository.queries, ['naruto']);
    expect(controller.results.items.single.title, 'naruto 1');
  });

  test('does not auto-search very short queries', () async {
    controller.onQueryChanged('ab');
    await settle();
    expect(repository.queries, isEmpty);
    expect(controller.hasActiveSearch, isFalse);
  });

  test('submitting searches immediately and records the term', () async {
    controller.submit(' K ');
    await settle();
    expect(repository.queries, ['K']);
    expect(controller.recentSearches.terms, ['K']);
  });

  test('re-committing the same query does not refetch', () async {
    controller.submit('bleach');
    await settle();
    controller.onQueryChanged('bleach ');
    controller.submit('bleach');
    await settle();
    expect(repository.queries, ['bleach']);
  });

  test('clearing the field clears the search', () async {
    controller.submit('bleach');
    await settle();
    controller.onQueryChanged('');
    expect(controller.hasActiveSearch, isFalse);
    expect(controller.results.items, isEmpty);
  });

  test('recent searches are de-duplicated and capped', () async {
    final store = controller.recentSearches;
    for (var i = 0; i < 15; i++) {
      await store.add('term $i');
    }
    await store.add('TERM 14');
    expect(store.terms.length, RecentSearchesStore.maxTerms);
    expect(store.terms.first, 'TERM 14');
    expect(store.terms.where((t) => t.toLowerCase() == 'term 14').length, 1);
  });
}

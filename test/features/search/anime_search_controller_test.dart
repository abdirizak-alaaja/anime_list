import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/features/search/controllers/anime_search_controller.dart';
import 'package:anime_list/features/search/data/recent_searches_store.dart';
import 'package:anime_list/features/search/repositories/search_repository.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:anime_list/core/state/paged_list_controller.dart';
import 'package:anime_list/features/search/models/search_filters.dart';
import 'package:anime_list/features/search/models/search_sort.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:anime_list/shared/models/paginated.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearchRepository implements SearchRepository {
  final queries = <String?>[];
  final filters = <SearchFilters>[];
  var genreCalls = 0;

  @override
  PageFetcher<Anime> fetcherFor({
    required String text,
    required SearchFilters filters,
    required SearchSort sort,
  }) {
    return (page, {forceRefresh = false}) async {
      queries.add(text);
      this.filters.add(filters);
      return Paginated(
        items: [Anime(malId: page, title: '$text $page')],
        currentPage: page,
        hasNextPage: false,
      );
    };
  }

  @override
  Future<List<({int id, String name})>> genres() async {
    genreCalls++;
    return [(id: 1, name: 'Action')];
  }
}

void main() {
  const debounce = Duration(milliseconds: 20);
  late _FakeSearchRepository repository;
  late AnimeSearchController controller;

  setUp(() {
    repository = _FakeSearchRepository();
    controller = AnimeSearchController(
      searchRepository: repository,
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

  test('filters alone trigger a browse search', () async {
    controller.setFilters(const SearchFilters(type: AnimeType.movie));
    await settle();
    expect(controller.hasActiveSearch, isTrue);
    expect(repository.filters.single.type, AnimeType.movie);
  });

  test('changing sort refetches, re-applying the same sort does not', () async {
    controller.submit('one piece');
    await settle();
    controller.setSort(SearchSort.score);
    controller.setSort(SearchSort.score);
    await settle();
    expect(repository.queries, ['one piece', 'one piece']);
  });

  test('clearing filters ends a filter-only search', () async {
    controller.setFilters(const SearchFilters(minScore: 8));
    await settle();
    controller.clearFilters();
    expect(controller.hasActiveSearch, isFalse);
  });

  test('genres are fetched once', () async {
    await controller.genres();
    await controller.genres();
    expect(repository.genreCalls, 1);
    expect(controller.genreNames, {1: 'Action'});
  });
}

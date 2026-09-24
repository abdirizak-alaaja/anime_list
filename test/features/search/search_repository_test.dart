import 'package:anime_list/core/network/jikan_api.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:anime_list/features/search/models/search_filters.dart';
import 'package:anime_list/features/search/models/search_sort.dart';
import 'package:anime_list/features/search/repositories/search_repository.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  late List<Uri> requests;

  SearchRepository build(Object? Function(Uri) handler) {
    requests = [];
    final deps = testDependencies(
      handler: (uri) {
        requests.add(uri);
        return handler(uri);
      },
    );
    return SearchRepository(deps.jikan);
  }

  Map<String, Object?> seasonPage(
    List<Map<String, Object?>> items, {
    bool hasNext = false,
  }) => {
    'pagination': {'has_next_page': hasNext},
    'data': items,
  };

  test('text search uses the search endpoint with sorting', () async {
    final repo = build((_) => {'data': []});
    await repo.fetcherFor(
      text: 'naruto',
      filters: const SearchFilters(type: AnimeType.tv),
      sort: SearchSort.score,
    )(1);
    expect(requests.single.path, '/v4/anime');
    expect(requests.single.queryParameters, containsPair('q', 'naruto'));
    expect(requests.single.queryParameters, containsPair('type', 'tv'));
    expect(requests.single.queryParameters, containsPair('order_by', 'score'));
  });

  test('season filters browse the seasonal endpoint', () async {
    final repo = build(
      (_) => seasonPage([
        {'mal_id': 1, 'title': 'Kept', 'type': 'TV', 'score': 8.0},
        {
          'mal_id': 2,
          'title': 'Dropped by min score',
          'type': 'TV',
          'score': 5.0,
        },
      ]),
    );
    final page = await repo.fetcherFor(
      text: '',
      filters: const SearchFilters(
        year: 2023,
        season: AnimeSeason.fall,
        type: AnimeType.tv,
        minScore: 7,
      ),
      sort: SearchSort.relevance,
    )(1);

    expect(requests.single.path, '/v4/seasons/2023/fall');
    expect(requests.single.queryParameters, containsPair('filter', 'tv'));
    expect(page.items.map((a) => a.title), ['Kept']);
    expect(page.hasNextPage, isFalse);
  });

  test('a year without a season walks all four seasons', () async {
    final repo = build((uri) {
      final season = uri.pathSegments.last;
      return seasonPage([
        {'mal_id': season.hashCode, 'title': season},
      ]);
    });
    final fetch = repo.fetcherFor(
      text: '',
      filters: const SearchFilters(year: 2020),
      sort: SearchSort.relevance,
    );

    final first = await fetch(1);
    expect(requests.map((u) => u.pathSegments.last), [
      'winter',
      'spring',
      'summer',
    ], reason: 'up to three requests per page when matches are scarce');
    expect(first.hasNextPage, isTrue);

    final second = await fetch(2);
    expect(second.items.single.title, 'fall');
    expect(second.hasNextPage, isFalse);
  });

  test('genres come from the API', () async {
    final repo = build((_) => fixture('genres.json'));
    final genres = await repo.genres();
    expect(genres, isNotEmpty);
    expect(genres.map((g) => g.name), contains('Action'));
  });

  test('uses the configured page size', () {
    expect(JikanApi.pageSize, lessThanOrEqualTo(25));
    expect(RateLimiter.publicJikanLimits.first.count, 3);
    expect(JikanHttpClient.defaultCacheTtl, isNot(Duration.zero));
  });
}

import 'package:anime_list/features/search/models/search_filters.dart';
import 'package:anime_list/features/search/models/search_sort.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:anime_list/shared/models/anime_enums.dart';
import 'package:anime_list/shared/models/named_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchFilters', () {
    test('counts active filter groups', () {
      expect(SearchFilters.none.activeCount, 0);
      expect(SearchFilters.none.isEmpty, isTrue);
      const filters = SearchFilters(
        genreIds: {1, 2},
        type: AnimeType.tv,
        year: 2023,
        season: AnimeSeason.fall,
      );
      expect(filters.activeCount, 3);
    });

    test('copyWith can clear values and drops season without a year', () {
      const filters = SearchFilters(year: 2020, season: AnimeSeason.spring);
      expect(filters.copyWith(season: () => null).season, isNull);
      final cleared = filters.copyWith(year: () => null);
      expect(cleared.year, isNull);
      expect(cleared.season, isNull);
    });

    test('equality ignores genre order', () {
      expect(
        const SearchFilters(genreIds: {1, 2}),
        const SearchFilters(genreIds: {2, 1}),
      );
    });

    test('builds a Jikan query with sorting', () {
      const filters = SearchFilters(
        genreIds: {4, 1},
        status: AnimeStatus.airing,
        minScore: 7,
      );
      final params = filters.toQuery('', SearchSort.newest).toQueryParameters();
      expect(params['genres'], '1,4');
      expect(params['status'], 'airing');
      expect(params['min_score'], 7.0);
      expect(params['order_by'], 'start_date');
      expect(params['sort'], 'desc');
    });

    test('"best match" keeps Jikan relevance only for text searches', () {
      final withText = SearchFilters.none
          .toQuery('naruto', SearchSort.relevance)
          .toQueryParameters();
      expect(withText['order_by'], isNull);

      final browse = SearchFilters.none
          .toQuery('', SearchSort.relevance)
          .toQueryParameters();
      expect(browse['order_by'], 'popularity');
      expect(browse['sort'], 'asc');
    });

    test('client-side matching', () {
      const anime = Anime(
        malId: 1,
        title: 'Sousou no Frieren',
        titleEnglish: "Frieren: Beyond Journey's End",
        type: 'TV',
        status: 'Finished Airing',
        rating: 'PG-13 - Teens 13 or older',
        score: 9.3,
        genres: [NamedResource(malId: 2, name: 'Adventure')],
        demographics: [NamedResource(malId: 27, name: 'Shounen')],
      );

      expect(
        const SearchFilters(
          genreIds: {2, 27},
          type: AnimeType.tv,
          status: AnimeStatus.complete,
          rating: AnimeRating.pg13,
          minScore: 9,
        ).matches(anime, text: 'journey'),
        isTrue,
      );
      expect(const SearchFilters(genreIds: {1}).matches(anime), isFalse);
      expect(
        const SearchFilters(type: AnimeType.movie).matches(anime),
        isFalse,
      );
      expect(
        const SearchFilters(status: AnimeStatus.airing).matches(anime),
        isFalse,
      );
      expect(const SearchFilters(minScore: 9.5).matches(anime), isFalse);
      expect(SearchFilters.none.matches(anime, text: 'bleach'), isFalse);
    });
  });

  group('SearchSort comparator', () {
    test('sorts missing values last', () {
      const a = Anime(malId: 1, title: 'B', score: 7);
      const b = Anime(malId: 2, title: 'a', score: null);
      const c = Anime(malId: 3, title: 'C', score: 9);
      final byScore = [a, b, c]..sort(SearchSort.score.comparator);
      expect(byScore.map((x) => x.malId), [3, 1, 2]);

      final byTitle = [a, b, c]..sort(SearchSort.title.comparator);
      expect(byTitle.map((x) => x.malId), [2, 1, 3]);
    });
  });
}

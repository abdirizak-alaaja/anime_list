import '../../../core/network/jikan_api.dart';
import '../../../core/state/paged_list_controller.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_enums.dart';
import '../../../shared/models/paginated.dart';
import '../models/search_filters.dart';
import '../models/search_sort.dart';

/// Anime search and filtered browsing backed by Jikan.
class SearchRepository {
  const SearchRepository(this._api);

  final JikanApi _api;

  /// Returns a page fetcher for one search.
  ///
  /// Each call returns a fresh fetcher, since seasonal browsing keeps a
  /// cursor across pages.
  PageFetcher<Anime> fetcherFor({
    required String text,
    required SearchFilters filters,
    required SearchSort sort,
  }) {
    if (filters.usesSeasonalBrowse) {
      return _SeasonalBrowser(_api, text: text, filters: filters).fetch;
    }
    final query = filters.toQuery(text, sort);
    return (page, {forceRefresh = false}) =>
        _api.searchAnime(query, page: page, forceRefresh: forceRefresh);
  }

  /// Genres, themes and demographics for the filter sheet.
  Future<List<({int id, String name})>> genres() async => [
    for (final genre in await _api.getAnimeGenres())
      (id: genre.malId, name: genre.name),
  ];
}

/// Pages through `/seasons/{year}/{season}` (every season of the year when
/// no season is chosen), applying the remaining filters on the device.
///
/// Fetches a few upstream pages per call when filters are selective, but
/// never more than [_maxRequestsPerPage], to stay well inside Jikan's rate
/// limits.
class _SeasonalBrowser {
  _SeasonalBrowser(this._api, {required this.text, required this.filters})
    : _seasons = filters.season == null
          ? AnimeSeason.values
          : [filters.season!];

  static const _maxRequestsPerPage = 3;
  static const _targetItemsPerPage = 12;

  final JikanApi _api;
  final String text;
  final SearchFilters filters;
  final List<AnimeSeason> _seasons;

  int _seasonIndex = 0;
  int _upstreamPage = 1;

  bool get _exhausted => _seasonIndex >= _seasons.length;

  Future<Paginated<Anime>> fetch(int page, {bool forceRefresh = false}) async {
    if (page == 1) {
      _seasonIndex = 0;
      _upstreamPage = 1;
    }

    final matches = <Anime>[];
    var requests = 0;
    while (!_exhausted &&
        requests < _maxRequestsPerPage &&
        matches.length < _targetItemsPerPage) {
      final result = await _api.getSeason(
        year: filters.year!,
        season: _seasons[_seasonIndex],
        type: filters.type,
        page: _upstreamPage,
        forceRefresh: forceRefresh,
      );
      requests++;
      matches.addAll(result.items.where((a) => filters.matches(a, text: text)));

      if (result.hasNextPage) {
        _upstreamPage++;
      } else {
        _seasonIndex++;
        _upstreamPage = 1;
      }
    }

    return Paginated(
      items: matches,
      currentPage: page,
      hasNextPage: !_exhausted,
    );
  }
}

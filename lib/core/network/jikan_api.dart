import '../../shared/models/anime.dart';
import '../../shared/models/anime_character.dart';
import '../../shared/models/anime_enums.dart';
import '../../shared/models/anime_query.dart';
import '../../shared/models/anime_recommendation.dart';
import '../../shared/models/named_resource.dart';
import '../../shared/models/paginated.dart';
import '../errors/app_exception.dart';
import '../utils/json.dart';
import 'jikan_http_client.dart';

/// Typed access to the Jikan v4 endpoints the app uses.
///
/// Anime by genre, type, status, rating or score are all served by
/// [searchAnime] through [AnimeQuery]; anime by season/year by [getSeason].
class JikanApi {
  JikanApi(this._client);

  final JikanHttpClient _client;

  /// Page size used by list endpoints (Jikan's maximum is 25).
  static const pageSize = 24;

  /// Only return safe-for-work entries.
  static const _sfw = {'sfw': 'true'};

  static const _listTtl = Duration(minutes: 15);
  static const _detailsTtl = Duration(hours: 1);
  static const _genresTtl = Duration(days: 1);

  /// `/top/anime`
  Future<Paginated<Anime>> getTopAnime({
    TopAnimeFilter? filter,
    AnimeType? type,
    int page = 1,
    bool forceRefresh = false,
  }) => _animePage(
    'top/anime',
    {'filter': filter?.apiValue, 'type': type?.apiValue},
    page: page,
    forceRefresh: forceRefresh,
  );

  /// `/seasons/now`
  Future<Paginated<Anime>> getCurrentSeason({
    AnimeType? type,
    int page = 1,
    bool forceRefresh = false,
  }) => _animePage(
    'seasons/now',
    {'filter': type?.apiValue},
    page: page,
    forceRefresh: forceRefresh,
  );

  /// `/seasons/upcoming`
  Future<Paginated<Anime>> getUpcomingSeason({
    AnimeType? type,
    int page = 1,
    bool forceRefresh = false,
  }) => _animePage(
    'seasons/upcoming',
    {'filter': type?.apiValue},
    page: page,
    forceRefresh: forceRefresh,
  );

  /// `/seasons/{year}/{season}`
  Future<Paginated<Anime>> getSeason({
    required int year,
    required AnimeSeason season,
    AnimeType? type,
    int page = 1,
    bool forceRefresh = false,
  }) => _animePage(
    'seasons/$year/${season.apiValue}',
    {'filter': type?.apiValue},
    page: page,
    forceRefresh: forceRefresh,
  );

  /// `/anime` search with filters and sorting.
  Future<Paginated<Anime>> searchAnime(
    AnimeQuery query, {
    int page = 1,
    bool forceRefresh = false,
  }) => _animePage(
    'anime',
    query.toQueryParameters(),
    page: page,
    forceRefresh: forceRefresh,
  );

  /// `/anime/{id}`
  Future<Anime> getAnime(int id, {bool forceRefresh = false}) =>
      _animeDetails('anime/$id', forceRefresh);

  /// `/anime/{id}/full`, which adds studios, relations, streaming, etc.
  Future<Anime> getAnimeFull(int id, {bool forceRefresh = false}) =>
      _animeDetails('anime/$id/full', forceRefresh);

  /// `/random/anime`. Never cached, so each call returns a new entry.
  ///
  /// The endpoint has no `sfw` filter; callers should check [Anime.rating].
  Future<Anime> getRandomAnime() =>
      _animeDetails('random/anime', true, cacheTtl: Duration.zero);

  /// `/anime/{id}/characters`, main characters first.
  Future<List<AnimeCharacter>> getAnimeCharacters(
    int id, {
    bool forceRefresh = false,
  }) async {
    final json = await _client.get(
      'anime/$id/characters',
      cacheTtl: _detailsTtl,
      forceRefresh: forceRefresh,
    );
    final characters = _parseList(json, AnimeCharacter.fromJson);
    // Stable sort: main cast first, then by popularity.
    return characters..sort((a, b) {
      if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
      return (b.favorites ?? 0).compareTo(a.favorites ?? 0);
    });
  }

  /// `/anime/{id}/recommendations`
  Future<List<AnimeRecommendation>> getAnimeRecommendations(
    int id, {
    bool forceRefresh = false,
  }) async {
    final json = await _client.get(
      'anime/$id/recommendations',
      cacheTtl: _detailsTtl,
      forceRefresh: forceRefresh,
    );
    return _parseList(json, AnimeRecommendation.fromJson);
  }

  /// `/genres/anime` — genres, themes and demographics, sorted by name.
  /// Explicit genres are excluded.
  Future<List<NamedResource>> getAnimeGenres() async {
    final json = await _client.get('genres/anime', cacheTtl: _genresTtl);
    final seen = <int>{};
    return [
      for (final genre in _parseList(json, NamedResource.fromJson))
        if (!_explicitGenreIds.contains(genre.malId) && seen.add(genre.malId))
          genre,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// MyAnimeList ids of the explicit genres (Hentai, Erotica).
  static const _explicitGenreIds = {12, 49};

  Future<Paginated<Anime>> _animePage(
    String path,
    Map<String, Object?> query, {
    required int page,
    required bool forceRefresh,
  }) async {
    final json = await _client.get(
      path,
      query: {...query, ..._sfw, 'page': page, 'limit': pageSize},
      cacheTtl: _listTtl,
      forceRefresh: forceRefresh,
    );
    return Paginated.fromJson(json, Anime.fromJson, requestedPage: page);
  }

  Future<Anime> _animeDetails(
    String path,
    bool forceRefresh, {
    Duration cacheTtl = _detailsTtl,
  }) async {
    final json = await _client.get(
      path,
      cacheTtl: cacheTtl,
      forceRefresh: forceRefresh,
    );
    final data = json.obj('data');
    final anime = data == null ? null : Anime.fromJson(data);
    if (anime == null) throw const NotFoundException();
    return anime;
  }

  static List<T> _parseList<T>(Json json, T? Function(Json) parse) => [
    for (final item in json.objList('data')) ?parse(item),
  ];
}

import '../../../core/network/jikan_api.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_query.dart';
import '../../../shared/models/paginated.dart';

/// Anime search backed by Jikan's `/anime` endpoint.
class SearchRepository {
  const SearchRepository(this._api);

  final JikanApi _api;

  Future<Paginated<Anime>> search(
    AnimeQuery query, {
    int page = 1,
    bool forceRefresh = false,
  }) => _api.searchAnime(query, page: page, forceRefresh: forceRefresh);
}

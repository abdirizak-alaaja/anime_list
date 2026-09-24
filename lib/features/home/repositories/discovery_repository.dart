import '../../../core/network/jikan_api.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_enums.dart';
import '../../../shared/models/paginated.dart';
import '../models/discovery_section.dart';

/// Maps each [DiscoverySection] to its Jikan endpoint.
class DiscoveryRepository {
  const DiscoveryRepository(this._api);

  final JikanApi _api;

  Future<Paginated<Anime>> fetch(
    DiscoverySection section, {
    int page = 1,
    bool forceRefresh = false,
  }) => switch (section) {
    DiscoverySection.trending => _api.getTopAnime(
      filter: TopAnimeFilter.airing,
      page: page,
      forceRefresh: forceRefresh,
    ),
    DiscoverySection.thisSeason => _api.getCurrentSeason(
      page: page,
      forceRefresh: forceRefresh,
    ),
    DiscoverySection.upcoming => _api.getUpcomingSeason(
      page: page,
      forceRefresh: forceRefresh,
    ),
    DiscoverySection.popular => _api.getTopAnime(
      filter: TopAnimeFilter.byPopularity,
      page: page,
      forceRefresh: forceRefresh,
    ),
    DiscoverySection.topRated => _api.getTopAnime(
      page: page,
      forceRefresh: forceRefresh,
    ),
  };
}

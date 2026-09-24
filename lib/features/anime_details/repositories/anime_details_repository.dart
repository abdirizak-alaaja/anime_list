import '../../../core/network/jikan_api.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_character.dart';
import '../../../shared/models/anime_recommendation.dart';

/// Everything shown on the details screen.
class AnimeDetailsRepository {
  const AnimeDetailsRepository(this._api);

  final JikanApi _api;

  Future<Anime> details(int id, {bool forceRefresh = false}) =>
      _api.getAnimeFull(id, forceRefresh: forceRefresh);

  Future<List<AnimeCharacter>> characters(
    int id, {
    bool forceRefresh = false,
  }) => _api.getAnimeCharacters(id, forceRefresh: forceRefresh);

  Future<List<AnimeRecommendation>> recommendations(
    int id, {
    bool forceRefresh = false,
  }) => _api.getAnimeRecommendations(id, forceRefresh: forceRefresh);
}

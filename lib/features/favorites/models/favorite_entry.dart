import '../../../core/utils/json.dart';
import '../../../shared/models/anime_snapshot.dart';

/// A favorited anime and when it was favorited.
class FavoriteEntry {
  const FavoriteEntry({required this.anime, required this.addedAt});

  final AnimeSnapshot anime;
  final DateTime addedAt;

  int get malId => anime.malId;

  Json toJson() => {
    'anime': anime.toJson(),
    'added_at': addedAt.toIso8601String(),
  };

  static FavoriteEntry? fromJson(Json json) {
    final animeJson = json.obj('anime');
    final anime = animeJson == null ? null : AnimeSnapshot.fromJson(animeJson);
    if (anime == null) return null;
    return FavoriteEntry(
      anime: anime,
      addedAt: json.date('added_at') ?? DateTime.now(),
    );
  }
}

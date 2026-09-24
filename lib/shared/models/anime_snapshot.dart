import '../../core/utils/json.dart';
import 'anime.dart';
import 'anime_enums.dart';

/// The subset of an [Anime] stored locally for the library and favorites,
/// so they can be shown offline.
class AnimeSnapshot {
  const AnimeSnapshot({
    required this.malId,
    required this.title,
    this.titleJapanese,
    this.imageUrl,
    this.largeImageUrl,
    this.type,
    this.episodes,
    this.score,
    this.status,
    this.season,
    this.year,
  });

  factory AnimeSnapshot.fromAnime(Anime anime) => AnimeSnapshot(
    malId: anime.malId,
    title: anime.title,
    titleJapanese: anime.titleJapanese,
    imageUrl: anime.imageUrl,
    largeImageUrl: anime.largeImageUrl,
    type: anime.type,
    episodes: anime.episodes,
    score: anime.score,
    status: anime.status,
    season: anime.startSeason,
    year: anime.startYear,
  );

  final int malId;
  final String title;
  final String? titleJapanese;
  final String? imageUrl;
  final String? largeImageUrl;
  final String? type;
  final int? episodes;
  final double? score;

  /// Airing status as reported by Jikan, e.g. "Currently Airing".
  final String? status;
  final AnimeSeason? season;
  final int? year;

  /// Merges fresher API data, keeping stored values Jikan left out.
  AnimeSnapshot mergeWith(Anime anime) => AnimeSnapshot(
    malId: malId,
    title: anime.title,
    titleJapanese: anime.titleJapanese ?? titleJapanese,
    imageUrl: anime.imageUrl ?? imageUrl,
    largeImageUrl: anime.largeImageUrl ?? largeImageUrl,
    type: anime.type ?? type,
    episodes: anime.episodes ?? episodes,
    score: anime.score ?? score,
    status: anime.status ?? status,
    season: anime.startSeason ?? season,
    year: anime.startYear ?? year,
  );

  /// A minimal [Anime] for cards and as a details-screen preview.
  Anime toAnime() => Anime(
    malId: malId,
    title: title,
    titleJapanese: titleJapanese,
    imageUrl: imageUrl,
    largeImageUrl: largeImageUrl,
    type: type,
    episodes: episodes,
    score: score,
    status: status,
    season: season,
    year: year,
  );

  Json toJson() => {
    'mal_id': malId,
    'title': title,
    'title_japanese': titleJapanese,
    'image_url': imageUrl,
    'large_image_url': largeImageUrl,
    'type': type,
    'episodes': episodes,
    'score': score,
    'status': status,
    'season': season?.apiValue,
    'year': year,
  };

  static AnimeSnapshot? fromJson(Json json) {
    final id = json.integer('mal_id');
    final title = json.str('title');
    if (id == null || title == null) return null;
    return AnimeSnapshot(
      malId: id,
      title: title,
      titleJapanese: json.str('title_japanese'),
      imageUrl: json.str('image_url'),
      largeImageUrl: json.str('large_image_url'),
      type: json.str('type'),
      episodes: json.integer('episodes'),
      score: json.decimal('score'),
      status: json.str('status'),
      season: AnimeSeason.tryParse(json.str('season')),
      year: json.integer('year'),
    );
  }
}

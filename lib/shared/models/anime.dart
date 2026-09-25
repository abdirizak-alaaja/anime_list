import '../../core/utils/json.dart';
import 'anime_enums.dart';
import 'named_resource.dart';

/// An anime entry as returned by Jikan (`/anime`, `/top/anime`, `/seasons`,
/// `/anime/{id}/full`).
///
/// Only [malId] and [title] are guaranteed; everything else may be absent.
class Anime {
  const Anime({
    required this.malId,
    required this.title,
    this.url,
    this.imageUrl,
    this.largeImageUrl,
    this.trailerYoutubeId,
    this.titleEnglish,
    this.titleJapanese,
    this.synonyms = const [],
    this.type,
    this.source,
    this.episodes,
    this.status,
    this.airing = false,
    this.airedFrom,
    this.airedTo,
    this.airedLabel,
    this.duration,
    this.rating,
    this.score,
    this.scoredBy,
    this.rank,
    this.popularity,
    this.members,
    this.favorites,
    this.synopsis,
    this.background,
    this.season,
    this.year,
    this.broadcast,
    this.producers = const [],
    this.licensors = const [],
    this.studios = const [],
    this.genres = const [],
    this.themes = const [],
    this.demographics = const [],
  });

  final int malId;
  final String title;
  final String? url;
  final String? imageUrl;
  final String? largeImageUrl;
  final String? trailerYoutubeId;
  final String? titleEnglish;
  final String? titleJapanese;
  final List<String> synonyms;
  final String? type;
  final String? source;
  final int? episodes;
  final String? status;
  final bool airing;
  final DateTime? airedFrom;
  final DateTime? airedTo;
  final String? airedLabel;
  final String? duration;
  final String? rating;
  final double? score;
  final int? scoredBy;
  final int? rank;
  final int? popularity;
  final int? members;
  final int? favorites;
  final String? synopsis;
  final String? background;
  final AnimeSeason? season;
  final int? year;
  final String? broadcast;
  final List<NamedResource> producers;
  final List<NamedResource> licensors;
  final List<NamedResource> studios;
  final List<NamedResource> genres;
  final List<NamedResource> themes;
  final List<NamedResource> demographics;

  /// Year the anime started, falling back to the air date when Jikan doesn't
  /// provide `year` (common for movies and upcoming titles).
  int? get startYear => year ?? airedFrom?.year;

  /// Season the anime started, derived from the air date when missing.
  AnimeSeason? get startSeason =>
      season ??
      (airedFrom == null ? null : AnimeSeason.forMonth(airedFrom!.month));

  /// Genres, themes and demographics combined for display.
  List<NamedResource> get allGenres => [...genres, ...themes, ...demographics];

  /// Returns `null` for entries without an id or a title.
  static Anime? fromJson(Json json) {
    final id = json.integer('mal_id');
    final title = json.str('title') ?? _defaultTitle(json);
    if (id == null || title == null) return null;

    final jpg = json.obj('images')?.obj('jpg');
    final webp = json.obj('images')?.obj('webp');
    final aired = json.obj('aired');

    return Anime(
      malId: id,
      title: title,
      url: json.str('url'),
      imageUrl: jpg?.str('image_url') ?? webp?.str('image_url'),
      largeImageUrl:
          jpg?.str('large_image_url') ??
          webp?.str('large_image_url') ??
          jpg?.str('image_url'),
      trailerYoutubeId: _youtubeId(json.obj('trailer')),
      titleEnglish: json.str('title_english'),
      titleJapanese: json.str('title_japanese'),
      synonyms: json.strList('title_synonyms'),
      type: json.str('type'),
      source: json.str('source'),
      episodes: json.integer('episodes'),
      status: json.str('status'),
      airing: json.boolean('airing') ?? false,
      airedFrom: aired?.date('from'),
      airedTo: aired?.date('to'),
      airedLabel: _airedLabel(aired?.str('string')),
      duration: _clean(json.str('duration')),
      rating: json.str('rating'),
      score: json.decimal('score'),
      scoredBy: json.integer('scored_by'),
      rank: json.integer('rank'),
      popularity: json.integer('popularity'),
      members: json.integer('members'),
      favorites: json.integer('favorites'),
      synopsis: _stripMalRewrite(json.str('synopsis')),
      background: json.str('background'),
      season: AnimeSeason.tryParse(json.str('season')),
      year: json.integer('year'),
      broadcast: _clean(json.obj('broadcast')?.str('string')),
      producers: NamedResource.listFrom(json.objList('producers')),
      licensors: NamedResource.listFrom(json.objList('licensors')),
      studios: NamedResource.listFrom(json.objList('studios')),
      genres: NamedResource.listFrom(json.objList('genres')),
      themes: NamedResource.listFrom(json.objList('themes')),
      demographics: NamedResource.listFrom(json.objList('demographics')),
    );
  }

  static String? _defaultTitle(Json json) {
    for (final title in json.objList('titles')) {
      if (title.str('type') == 'Default') return title.str('title');
    }
    return null;
  }

  /// Self-hosted Jikan often leaves `youtube_id` empty and only fills
  /// `embed_url` (e.g. `https://www.youtube-nocookie.com/embed/{id}?...`).
  static String? _youtubeId(Json? trailer) {
    if (trailer == null) return null;
    final id = trailer.str('youtube_id');
    if (id != null && id.isNotEmpty) return id;
    final embed = Uri.tryParse(trailer.str('embed_url') ?? '');
    final segments = embed?.pathSegments ?? const <String>[];
    final index = segments.indexOf('embed');
    if (index == -1 || index + 1 >= segments.length) return null;
    final embedded = segments[index + 1];
    return embedded.isEmpty ? null : embedded;
  }

  /// YouTube page for the trailer, if there is one.
  Uri? get trailerUri => trailerYoutubeId == null
      ? null
      : Uri.https('www.youtube.com', '/watch', {'v': trailerYoutubeId});

  /// Jikan uses "Unknown" as a placeholder in several string fields.
  static String? _clean(String? value) =>
      value == null || value == 'Unknown' ? null : value;

  static String? _airedLabel(String? value) =>
      value == null || value == 'Not available' ? null : value;

  /// Removes MyAnimeList's "[Written by MAL Rewrite]" footer.
  static String? _stripMalRewrite(String? synopsis) {
    if (synopsis == null) return null;
    final cleaned = synopsis
        .replaceAll(RegExp(r'\s*\[Written by MAL Rewrite\]\s*$'), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  @override
  bool operator ==(Object other) => other is Anime && other.malId == malId;

  @override
  int get hashCode => malId.hashCode;
}

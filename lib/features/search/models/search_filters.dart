import 'package:flutter/foundation.dart';

import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_enums.dart';
import '../../../shared/models/anime_query.dart';
import 'search_sort.dart';

/// User-selected search filters. Immutable; `null` means "any".
@immutable
class SearchFilters {
  const SearchFilters({
    this.genreIds = const {},
    this.type,
    this.status,
    this.season,
    this.year,
    this.rating,
    this.minScore,
  });

  static const none = SearchFilters();

  final Set<int> genreIds;
  final AnimeType? type;
  final AnimeStatus? status;

  /// Only applies together with [year].
  final AnimeSeason? season;
  final int? year;
  final AnimeRating? rating;
  final double? minScore;

  bool get isEmpty => activeCount == 0;

  /// Number of active filter groups, for the filter button badge.
  int get activeCount => [
    genreIds.isNotEmpty,
    type != null,
    status != null,
    year != null,
    rating != null,
    minScore != null,
  ].where((active) => active).length;

  /// Season/year browsing uses Jikan's seasonal endpoint, which matches
  /// anime by their premiere season. Jikan's search `start_date`/`end_date`
  /// parameters filter by first and *last* air date, which would wrongly
  /// drop ongoing shows.
  bool get usesSeasonalBrowse => year != null;

  SearchFilters copyWith({
    Set<int>? genreIds,
    ValueGetter<AnimeType?>? type,
    ValueGetter<AnimeStatus?>? status,
    ValueGetter<AnimeSeason?>? season,
    ValueGetter<int?>? year,
    ValueGetter<AnimeRating?>? rating,
    ValueGetter<double?>? minScore,
  }) {
    final nextYear = year == null ? this.year : year();
    return SearchFilters(
      genreIds: genreIds ?? this.genreIds,
      type: type == null ? this.type : type(),
      status: status == null ? this.status : status(),
      // A season without a year is meaningless.
      season: nextYear == null
          ? null
          : (season == null ? this.season : season()),
      year: nextYear,
      rating: rating == null ? this.rating : rating(),
      minScore: minScore == null ? this.minScore : minScore(),
    );
  }

  /// Builds a Jikan search query for the non-seasonal path.
  AnimeQuery toQuery(String text, SearchSort sort) {
    final order = sort.resolve(hasText: text.isNotEmpty);
    return AnimeQuery(
      text: text.isEmpty ? null : text,
      genreIds: genreIds.toList()..sort(),
      type: type,
      status: status,
      rating: rating,
      minScore: minScore,
      orderBy: order?.$1,
      sort: order?.$2,
    );
  }

  /// Client-side check for filters the seasonal endpoint can't apply.
  bool matches(Anime anime, {String text = ''}) {
    if (genreIds.isNotEmpty) {
      final ids = anime.allGenres.map((g) => g.malId).toSet();
      if (!genreIds.every(ids.contains)) return false;
    }
    if (type != null &&
        anime.type?.toLowerCase() != type!.label.toLowerCase()) {
      return false;
    }
    if (status != null && !_matchesStatus(anime.status)) return false;
    if (rating != null && !_matchesRating(anime.rating)) return false;
    if (minScore != null && (anime.score ?? 0) < minScore!) return false;
    if (text.isNotEmpty && !_matchesText(anime, text)) return false;
    return true;
  }

  bool _matchesStatus(String? value) => switch (status!) {
    AnimeStatus.airing => value == 'Currently Airing',
    AnimeStatus.complete => value == 'Finished Airing',
    AnimeStatus.upcoming => value == 'Not yet aired',
  };

  bool _matchesRating(String? value) {
    if (value == null) return false;
    return switch (rating!) {
      AnimeRating.g => value.startsWith('G '),
      AnimeRating.pg => value.startsWith('PG '),
      AnimeRating.pg13 => value.startsWith('PG-13'),
      AnimeRating.r17 => value.startsWith('R - 17'),
      AnimeRating.r => value.startsWith('R+'),
    };
  }

  static bool _matchesText(Anime anime, String text) {
    final needle = text.toLowerCase();
    return [
      anime.title,
      anime.titleEnglish,
      anime.titleJapanese,
      ...anime.synonyms,
    ].any((t) => t != null && t.toLowerCase().contains(needle));
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      setEquals(other.genreIds, genreIds) &&
      other.type == type &&
      other.status == status &&
      other.season == season &&
      other.year == year &&
      other.rating == rating &&
      other.minScore == minScore;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(genreIds),
    type,
    status,
    season,
    year,
    rating,
    minScore,
  );
}

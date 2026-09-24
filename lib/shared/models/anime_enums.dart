/// Enumerations matching Jikan's query parameter values.
library;

/// Common interface for enums that map to a Jikan query value.
abstract interface class ApiValue {
  String get apiValue;
  String get label;
}

enum AnimeType implements ApiValue {
  tv('tv', 'TV'),
  movie('movie', 'Movie'),
  ova('ova', 'OVA'),
  special('special', 'Special'),
  ona('ona', 'ONA'),
  music('music', 'Music'),
  tvSpecial('tv_special', 'TV Special');

  const AnimeType(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

enum AnimeStatus implements ApiValue {
  airing('airing', 'Airing'),
  complete('complete', 'Finished'),
  upcoming('upcoming', 'Upcoming');

  const AnimeStatus(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

enum AnimeRating implements ApiValue {
  g('g', 'G – All Ages'),
  pg('pg', 'PG – Children'),
  pg13('pg13', 'PG-13 – Teens 13+'),
  r17('r17', 'R – 17+'),
  r('r', 'R+ – Mild Nudity');

  const AnimeRating(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

enum AnimeOrderBy implements ApiValue {
  score('score', 'Score'),
  popularity('popularity', 'Popularity'),
  members('members', 'Members'),
  favorites('favorites', 'Favorites'),
  startDate('start_date', 'Air date'),
  title('title', 'Title'),
  rank('rank', 'Rank');

  const AnimeOrderBy(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

enum SortDirection implements ApiValue {
  asc('asc', 'Ascending'),
  desc('desc', 'Descending');

  const SortDirection(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

/// Filters for the `/top/anime` endpoint.
enum TopAnimeFilter implements ApiValue {
  airing('airing', 'Top Airing'),
  upcoming('upcoming', 'Top Upcoming'),
  byPopularity('bypopularity', 'Most Popular'),
  favorite('favorite', 'Most Favorited');

  const TopAnimeFilter(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;
}

enum AnimeSeason implements ApiValue {
  winter('winter', 'Winter'),
  spring('spring', 'Spring'),
  summer('summer', 'Summer'),
  fall('fall', 'Fall');

  const AnimeSeason(this.apiValue, this.label);

  @override
  final String apiValue;
  @override
  final String label;

  /// First month (1-12) of the season.
  int get startMonth => switch (this) {
    winter => 1,
    spring => 4,
    summer => 7,
    fall => 10,
  };

  static AnimeSeason? tryParse(String? value) {
    for (final season in values) {
      if (season.apiValue == value?.toLowerCase()) return season;
    }
    return null;
  }

  static AnimeSeason forMonth(int month) => values[((month - 1) ~/ 3) % 4];
}

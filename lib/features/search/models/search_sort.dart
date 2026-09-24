import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_enums.dart';

/// Sort options offered to the user.
enum SearchSort {
  relevance('Best match'),
  score('Highest score'),
  popularity('Most popular'),
  favorites('Most favorited'),
  newest('Newest'),
  oldest('Oldest'),
  title('Title A–Z');

  const SearchSort(this.label);

  final String label;

  /// Jikan `order_by`/`sort` for this option, or `null` to use Jikan's
  /// default ordering.
  ///
  /// "Best match" only makes sense with a text query; without one it falls
  /// back to popularity.
  (AnimeOrderBy, SortDirection)? resolve({required bool hasText}) =>
      switch (this) {
        relevance when hasText => null,
        relevance || popularity => (AnimeOrderBy.popularity, SortDirection.asc),
        score => (AnimeOrderBy.score, SortDirection.desc),
        favorites => (AnimeOrderBy.favorites, SortDirection.desc),
        newest => (AnimeOrderBy.startDate, SortDirection.desc),
        oldest => (AnimeOrderBy.startDate, SortDirection.asc),
        title => (AnimeOrderBy.title, SortDirection.asc),
      };

  /// Client-side comparator, used where Jikan can't sort (seasonal
  /// browsing). `null` keeps the server order.
  Comparator<Anime>? get comparator => switch (this) {
    relevance => null,
    score => (a, b) => _desc(a.score, b.score),
    // Popularity rank: lower is more popular.
    popularity => (a, b) => _asc(a.popularity, b.popularity),
    favorites => (a, b) => _desc(a.favorites, b.favorites),
    newest => (a, b) => _desc(a.airedFrom, b.airedFrom),
    oldest => (a, b) => _asc(a.airedFrom, b.airedFrom),
    title => (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  };

  /// Missing values always sort last.
  static int _asc<T extends Comparable<Object>>(T? a, T? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static int _desc<T extends Comparable<Object>>(T? a, T? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}

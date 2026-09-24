import 'anime_enums.dart';

/// Parameters for Jikan's `/anime` search endpoint.
///
/// Covers searching by text, genre, type, status, rating, score and air-date
/// range, with sorting.
class AnimeQuery {
  const AnimeQuery({
    this.text,
    this.genreIds = const [],
    this.type,
    this.status,
    this.rating,
    this.minScore,
    this.startDate,
    this.endDate,
    this.orderBy,
    this.sort,
  });

  final String? text;
  final List<int> genreIds;
  final AnimeType? type;
  final AnimeStatus? status;
  final AnimeRating? rating;
  final double? minScore;
  final DateTime? startDate;
  final DateTime? endDate;
  final AnimeOrderBy? orderBy;
  final SortDirection? sort;

  Map<String, Object?> toQueryParameters() => {
    'q': text?.trim(),
    'genres': genreIds.isEmpty ? null : genreIds.join(','),
    'type': type?.apiValue,
    'status': status?.apiValue,
    'rating': rating?.apiValue,
    'min_score': minScore,
    'start_date': _formatDate(startDate),
    'end_date': _formatDate(endDate),
    'order_by': orderBy?.apiValue,
    'sort': orderBy == null ? null : (sort ?? SortDirection.desc).apiValue,
  };

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

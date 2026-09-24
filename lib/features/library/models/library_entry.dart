import '../../../core/utils/json.dart';
import '../../../shared/models/anime_snapshot.dart';
import 'watch_status.dart';

/// An anime saved to the user's list, with their status and progress.
class LibraryEntry {
  const LibraryEntry({
    required this.anime,
    required this.status,
    required this.episodesWatched,
    required this.addedAt,
    required this.updatedAt,
  });

  final AnimeSnapshot anime;
  final WatchStatus status;
  final int episodesWatched;
  final DateTime addedAt;
  final DateTime updatedAt;

  int get malId => anime.malId;

  /// Total episodes, if Jikan knows it (it doesn't for many ongoing shows).
  int? get totalEpisodes => anime.episodes;

  /// Progress from 0 to 1, or `null` when the total is unknown.
  double? get progress {
    final total = totalEpisodes;
    if (total == null || total <= 0) return null;
    return (episodesWatched / total).clamp(0, 1).toDouble();
  }

  LibraryEntry copyWith({
    AnimeSnapshot? anime,
    WatchStatus? status,
    int? episodesWatched,
    DateTime? updatedAt,
  }) => LibraryEntry(
    anime: anime ?? this.anime,
    status: status ?? this.status,
    episodesWatched: episodesWatched ?? this.episodesWatched,
    addedAt: addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Json toJson() => {
    'anime': anime.toJson(),
    'status': status.storageKey,
    'episodes_watched': episodesWatched,
    'added_at': addedAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Returns `null` for corrupt records so one bad entry can't break the
  /// whole library.
  static LibraryEntry? fromJson(Json json) {
    final animeJson = json.obj('anime');
    final anime = animeJson == null ? null : AnimeSnapshot.fromJson(animeJson);
    if (anime == null) return null;
    final added = json.date('added_at') ?? DateTime.now();
    return LibraryEntry(
      anime: anime,
      status:
          WatchStatus.fromStorageKey(json.str('status')) ??
          WatchStatus.planToWatch,
      episodesWatched: (json.integer('episodes_watched') ?? 0).clamp(
        0,
        1 << 20,
      ),
      addedAt: added,
      updatedAt: json.date('updated_at') ?? added,
    );
  }
}

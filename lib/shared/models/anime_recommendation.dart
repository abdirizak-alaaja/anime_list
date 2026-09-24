import '../../core/utils/json.dart';

/// A user recommendation related to an anime
/// (`/anime/{id}/recommendations`).
class AnimeRecommendation {
  const AnimeRecommendation({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.votes,
  });

  final int malId;
  final String title;
  final String? imageUrl;
  final int? votes;

  static AnimeRecommendation? fromJson(Json json) {
    final entry = json.obj('entry');
    final id = entry?.integer('mal_id');
    final title = entry?.str('title');
    if (entry == null || id == null || title == null) return null;

    final jpg = entry.obj('images')?.obj('jpg');
    return AnimeRecommendation(
      malId: id,
      title: title,
      imageUrl: jpg?.str('large_image_url') ?? jpg?.str('image_url'),
      votes: json.integer('votes'),
    );
  }
}

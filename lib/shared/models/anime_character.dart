import '../../core/utils/json.dart';

/// A character appearing in an anime (`/anime/{id}/characters`).
class AnimeCharacter {
  const AnimeCharacter({
    required this.malId,
    required this.name,
    this.imageUrl,
    this.role,
    this.favorites,
    this.voiceActorName,
    this.voiceActorImageUrl,
  });

  final int malId;
  final String name;
  final String? imageUrl;

  /// "Main" or "Supporting".
  final String? role;
  final int? favorites;

  /// The Japanese voice actor, when listed.
  final String? voiceActorName;
  final String? voiceActorImageUrl;

  bool get isMain => role == 'Main';

  static AnimeCharacter? fromJson(Json json) {
    final character = json.obj('character');
    final id = character?.integer('mal_id');
    final name = character?.str('name');
    if (character == null || id == null || name == null) return null;

    final actors = json.objList('voice_actors');
    final japanese = actors.firstWhere(
      (a) => a.str('language') == 'Japanese',
      orElse: () => actors.isEmpty ? const {} : actors.first,
    );
    final person = japanese.obj('person');

    return AnimeCharacter(
      malId: id,
      name: name,
      imageUrl: _image(character),
      role: json.str('role'),
      favorites: json.integer('favorites'),
      voiceActorName: person?.str('name'),
      voiceActorImageUrl: person == null ? null : _image(person),
    );
  }

  static String? _image(Json json) {
    final images = json.obj('images');
    final url =
        images?.obj('jpg')?.str('image_url') ??
        images?.obj('webp')?.str('image_url');
    // MyAnimeList's generic "no picture" placeholder isn't worth loading.
    if (url == null || url.contains('questionmark')) return null;
    return url;
  }
}

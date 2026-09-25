import '../../core/utils/json.dart';

/// A character's full profile (`/characters/{id}/full`).
class CharacterProfile {
  const CharacterProfile({
    required this.malId,
    required this.name,
    this.nameKanji,
    this.nicknames = const [],
    this.imageUrl,
    this.favorites,
    this.about,
    this.animeography = const [],
    this.voiceActors = const [],
  });

  final int malId;
  final String name;
  final String? nameKanji;
  final List<String> nicknames;
  final String? imageUrl;
  final int? favorites;
  final String? about;

  /// Anime the character appears in, main roles first.
  final List<CharacterAppearance> animeography;

  /// Voice actors, Japanese first.
  final List<CharacterVoice> voiceActors;

  static CharacterProfile? fromJson(Json json) {
    final id = json.integer('mal_id');
    final name = json.str('name');
    if (id == null || name == null) return null;

    final anime = [
      for (final item in json.objList('anime'))
        ?CharacterAppearance.fromJson(item),
    ];
    final voices = [
      for (final item in json.objList('voices')) ?CharacterVoice.fromJson(item),
    ];

    return CharacterProfile(
      malId: id,
      name: name,
      nameKanji: json.str('name_kanji'),
      nicknames: json.strList('nicknames'),
      imageUrl: characterImage(json),
      favorites: json.integer('favorites'),
      about: json.str('about'),
      // Stable sorts keep Jikan's order within each group.
      animeography: anime
        ..sort((a, b) {
          if (a.isMain == b.isMain) return 0;
          return a.isMain ? -1 : 1;
        }),
      voiceActors: voices
        ..sort((a, b) {
          if (a.isJapanese == b.isJapanese) return 0;
          return a.isJapanese ? -1 : 1;
        }),
    );
  }
}

/// An anime a character appears in, and their role in it.
class CharacterAppearance {
  const CharacterAppearance({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.role,
  });

  final int malId;
  final String title;
  final String? imageUrl;

  /// "Main" or "Supporting".
  final String? role;

  bool get isMain => role == 'Main';

  static CharacterAppearance? fromJson(Json json) {
    final anime = json.obj('anime');
    final id = anime?.integer('mal_id');
    final title = anime?.str('title');
    if (anime == null || id == null || title == null) return null;

    final jpg = anime.obj('images')?.obj('jpg');
    return CharacterAppearance(
      malId: id,
      title: title,
      imageUrl: jpg?.str('large_image_url') ?? jpg?.str('image_url'),
      role: json.str('role'),
    );
  }
}

/// A voice actor for a character, in one language.
class CharacterVoice {
  const CharacterVoice({
    required this.malId,
    required this.name,
    this.imageUrl,
    this.language,
  });

  final int malId;
  final String name;
  final String? imageUrl;
  final String? language;

  bool get isJapanese => language == 'Japanese';

  static CharacterVoice? fromJson(Json json) {
    final person = json.obj('person');
    final id = person?.integer('mal_id');
    final name = person?.str('name');
    if (person == null || id == null || name == null) return null;

    return CharacterVoice(
      malId: id,
      name: name,
      imageUrl: characterImage(person),
      language: json.str('language'),
    );
  }
}

/// Portrait URL for a character or person, skipping MyAnimeList's generic
/// "no picture" placeholder.
String? characterImage(Json json) {
  final images = json.obj('images');
  final url =
      images?.obj('jpg')?.str('image_url') ??
      images?.obj('webp')?.str('image_url');
  if (url == null || url.contains('questionmark')) return null;
  return url;
}

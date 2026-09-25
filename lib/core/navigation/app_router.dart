import 'package:flutter/material.dart';

import '../../features/anime_details/screens/anime_details_screen.dart';
import '../../features/character/screens/character_profile_screen.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/anime_character.dart';

/// Central place for pushing app routes.
abstract final class AppRouter {
  /// Opens the details screen. Passing the already-known [preview] lets the
  /// screen render instantly while full details load.
  static Future<void> openAnime(
    BuildContext context, {
    required int malId,
    Anime? preview,
    Object? heroTag,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimeDetailsScreen(
          malId: malId,
          preview: preview,
          heroTag: heroTag,
        ),
      ),
    );
  }

  static Future<void> openAnimePreview(
    BuildContext context,
    Anime anime, {
    Object? heroTag,
  }) =>
      openAnime(context, malId: anime.malId, preview: anime, heroTag: heroTag);

  /// Opens a character's profile, showing [preview] while it loads.
  static Future<void> openCharacter(
    BuildContext context,
    AnimeCharacter preview,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CharacterProfileScreen(malId: preview.malId, preview: preview),
      ),
    );
  }
}

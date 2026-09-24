import 'package:flutter/material.dart';

import '../../features/anime_details/screens/anime_details_screen.dart';
import '../../shared/models/anime.dart';

/// Central place for pushing app routes.
abstract final class AppRouter {
  /// Opens the details screen. Passing the already-known [preview] lets the
  /// screen render instantly while full details load.
  static Future<void> openAnime(
    BuildContext context, {
    required int malId,
    Anime? preview,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimeDetailsScreen(malId: malId, preview: preview),
      ),
    );
  }

  static Future<void> openAnimePreview(BuildContext context, Anime anime) =>
      openAnime(context, malId: anime.malId, preview: anime);
}

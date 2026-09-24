import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/anime_card.dart';
import '../../../shared/widgets/anime_grid.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../../../shared/widgets/theme_mode_button.dart';
import '../models/favorite_entry.dart';
import '../repositories/favorites_repository.dart';

/// Favorites tab: works fully offline from locally stored data.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: favorites,
          builder: (context, _) => Text(
            favorites.count == 0
                ? 'Favorites'
                : 'Favorites (${favorites.count})',
          ),
        ),
        actions: const [ThemeModeButton()],
      ),
      body: ListenableBuilder(
        listenable: favorites,
        builder: (context, _) {
          final entries = favorites.entries;
          if (entries.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the heart on any anime to keep it here.',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              padding: const EdgeInsets.all(Insets.lg),
              gridDelegate: AnimeGridLayout.delegateFor(
                constraints.maxWidth - Insets.lg * 2,
                MediaQuery.textScalerOf(context),
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _FavoriteTile(entry: entries[index], favorites: favorites),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.entry, required this.favorites});

  final FavoriteEntry entry;
  final FavoritesRepository favorites;

  Future<void> _remove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await favorites.remove(entry.malId);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${entry.anime.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => favorites.restore(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final anime = entry.anime.toAnime();
    return Stack(
      children: [
        Positioned.fill(
          child: AnimeCard(
            anime: anime,
            heroTag: posterHeroTag('favorites', anime.malId),
            onTap: () => AppRouter.openAnimePreview(
              context,
              anime,
              heroTag: posterHeroTag('favorites', anime.malId),
            ),
          ),
        ),
        // Covers the card's own favorite badge with a tappable remove button.
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            tooltip: 'Remove from favorites',
            onPressed: () => _remove(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
            ),
            iconSize: 18,
            icon: const Icon(Icons.favorite_rounded),
            color: AppColors.favorite,
          ),
        ),
      ],
    );
  }
}

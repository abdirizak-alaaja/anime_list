import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/anime.dart';

/// Heart toggle for an anime; rebuilds when favorites change.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.anime, this.color});

  final Anime anime;

  /// Icon color when not a favorite (defaults to the icon theme).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;

    return ListenableBuilder(
      listenable: favorites,
      builder: (context, _) {
        final isFavorite = favorites.isFavorite(anime.malId);
        return IconButton(
          tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          isSelected: isFavorite,
          onPressed: () async {
            final added = await favorites.toggle(anime);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    added ? 'Added to favorites' : 'Removed from favorites',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
          },
          icon: Icon(Icons.favorite_border_rounded, color: color),
          selectedIcon: const Icon(
            Icons.favorite_rounded,
            color: AppColors.favorite,
          ),
        );
      },
    );
  }
}

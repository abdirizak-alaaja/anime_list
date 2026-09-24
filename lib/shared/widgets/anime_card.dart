import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../models/anime.dart';
import 'anime_poster.dart';
import 'score_badge.dart';

/// Poster card used in carousels and grids.
///
/// Its height is [heightFor] a given width, so containers can size it
/// exactly and nothing overflows at large text sizes.
class AnimeCard extends StatelessWidget {
  const AnimeCard({
    super.key,
    required this.anime,
    this.onTap,
    this.isFavorite = false,
  });

  final Anime anime;
  final VoidCallback? onTap;
  final bool isFavorite;

  static const _textBlockHeight = 78.0;

  /// Total card height for a given [width], including the text block scaled
  /// by the user's text size setting.
  static double heightFor(double width, TextScaler textScaler) =>
      width / AnimePoster.aspectRatio +
      textScaler.scale(_textBlockHeight) +
      Insets.sm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = anime.titleJapanese;
    final meta = Formatters.dotted([
      anime.type,
      anime.episodes == null ? null : Formatters.episodes(anime.episodes),
      Formatters.seasonYear(anime.startSeason, anime.startYear),
    ]);

    return Semantics(
      button: onTap != null,
      label: anime.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: AnimePoster.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimePoster(imageUrl: anime.imageUrl),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: ScoreBadge(score: anime.score),
                  ),
                  if (isFavorite)
                    const Positioned(right: 6, top: 6, child: _FavoriteDot()),
                  if (anime.status case final status?)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: _StatusPill(status: status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            Expanded(
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'Currently Airing' => ('Airing', AppColors.watching),
      'Not yet aired' => ('Upcoming', AppColors.malBlueLight),
      _ => (null, null),
    };
    if (label == null || color == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FavoriteDot extends StatelessWidget {
  const _FavoriteDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Favorite',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.favorite_rounded,
            size: 14,
            color: AppColors.favorite,
          ),
        ),
      ),
    );
  }
}

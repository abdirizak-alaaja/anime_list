import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/anime_poster.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../models/library_entry.dart';
import 'episode_stepper.dart';
import 'status_picker.dart';

/// A My List row: poster, title, status, progress and episode controls.
class LibraryListTile extends StatelessWidget {
  const LibraryListTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onStatusTap,
    required this.onEpisodesChanged,
    this.heroTag,
  });

  final LibraryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;
  final ValueChanged<int> onEpisodesChanged;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anime = entry.anime;
    final progress = entry.progress;
    final color = entry.status.colorFor(theme.brightness);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // MyAnimeList-style status stripe.
              Container(width: 4, color: color),
              Padding(
                padding: const EdgeInsets.all(Insets.sm),
                child: SizedBox(
                  width: 64,
                  child: AspectRatio(
                    aspectRatio: AnimePoster.aspectRatio,
                    child: PosterHero(
                      tag: heroTag,
                      child: AnimePoster(
                        imageUrl: anime.imageUrl,
                        borderRadius: 6,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.xs,
                    Insets.sm,
                    Insets.xs,
                    Insets.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dotted([
                          anime.type,
                          if (anime.score != null)
                            '★ ${Formatters.score(anime.score)}',
                          Formatters.seasonYear(anime.season, anime.year),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Insets.sm,
                        children: [
                          StatusChip(status: entry.status, onTap: onStatusTap),
                          EpisodeStepper(
                            watched: entry.episodesWatched,
                            total: entry.totalEpisodes,
                            onChanged: onEpisodesChanged,
                            dense: true,
                          ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: Insets.xs),
                        LinearProgressIndicator(
                          value: progress,
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          semanticsLabel: 'Progress',
                          semanticsValue: '${(progress * 100).round()}%',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

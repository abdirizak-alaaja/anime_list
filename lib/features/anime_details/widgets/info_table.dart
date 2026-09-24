import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';

/// Key/value facts about an anime. Rows without data are omitted.
class InfoTable extends StatelessWidget {
  const InfoTable({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Type', anime.type),
      (
        'Episodes',
        anime.episodes?.toString() ?? (anime.airing ? 'Airing' : null),
      ),
      ('Duration', anime.duration),
      ('Status', anime.status),
      ('Aired', anime.airedLabel),
      ('Season', Formatters.seasonYear(anime.season, anime.year)),
      ('Broadcast', anime.broadcast),
      ('Source', anime.source),
      ('Rating', anime.rating),
      if (anime.favorites != null)
        ('Favorites', Formatters.thousands(anime.favorites!)),
    ].where((row) => row.$2 != null).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.sm,
        ),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Insets.xs + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(value!, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

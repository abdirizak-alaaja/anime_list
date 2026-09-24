import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';

/// MyAnimeList-style score/rank/popularity/members summary.
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final scoredBy = anime.scoredBy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _Stat(
                label: 'Score',
                value: Formatters.score(anime.score),
                caption: scoredBy == null
                    ? null
                    : '${Formatters.compactCount(scoredBy)} users',
                icon: Icons.star_rounded,
                iconColor: AppColors.score,
              ),
              const VerticalDivider(),
              _Stat(
                label: 'Ranked',
                value: anime.rank == null ? 'N/A' : '#${anime.rank}',
              ),
              const VerticalDivider(),
              _Stat(
                label: 'Popularity',
                value: anime.popularity == null
                    ? 'N/A'
                    : '#${anime.popularity}',
              ),
              const VerticalDivider(),
              _Stat(
                label: 'Members',
                value: anime.members == null
                    ? 'N/A'
                    : Formatters.compactCount(anime.members!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        label: '$label: $value${caption == null ? '' : ', $caption'}',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
            const SizedBox(height: Insets.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 18, color: iconColor),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

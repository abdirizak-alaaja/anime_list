import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_poster.dart';

/// Backdrop, large poster, titles and quick facts.
class DetailsHeader extends StatelessWidget {
  const DetailsHeader({super.key, required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final posterWidth = isWide ? 200.0 : 132.0;
    final english = anime.titleEnglish;

    return Stack(
      children: [
        // Backdrop: the poster, faded into the page background.
        Positioned.fill(
          bottom: 48,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ).createShader(rect),
            child: AnimePoster(
              imageUrl: anime.largeImageUrl ?? anime.imageUrl,
              borderRadius: 0,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Insets.lg,
            MediaQuery.paddingOf(context).top + kToolbarHeight,
            Insets.lg,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: posterWidth,
                child: AspectRatio(
                  aspectRatio: AnimePoster.aspectRatio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(blurRadius: 16, color: Colors.black45),
                      ],
                    ),
                    child: AnimePoster(
                      imageUrl: anime.largeImageUrl ?? anime.imageUrl,
                      borderRadius: 12,
                      semanticLabel: '${anime.title} poster',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      anime.title,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 4,
                    ),
                    if (english != null && english != anime.title) ...[
                      const SizedBox(height: Insets.xs),
                      Text(
                        english,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (anime.titleJapanese case final japanese?) ...[
                      const SizedBox(height: Insets.xs),
                      Text(
                        japanese,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: Insets.sm),
                    Text(
                      Formatters.dotted([
                        anime.type,
                        Formatters.seasonYear(
                          anime.startSeason,
                          anime.startYear,
                        ),
                        anime.status,
                      ]),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

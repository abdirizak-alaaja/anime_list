import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/async_state.dart';
import '../../../shared/models/anime_character.dart';
import '../../../shared/models/anime_recommendation.dart';
import '../../../shared/widgets/anime_poster.dart';
import '../../../shared/widgets/message_view.dart';
import '../../../shared/widgets/poster_hero.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer.dart';

/// A titled horizontal strip over an [AsyncState] list, with skeleton,
/// error and empty handling. Hidden entirely when the list is empty.
class MediaStrip<T> extends StatelessWidget {
  const MediaStrip({
    super.key,
    required this.title,
    required this.state,
    required this.itemBuilder,
    required this.onRetry,
    this.itemWidth = 104,
  });

  final String title;
  final AsyncState<List<T>> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final height =
        itemWidth / AnimePoster.aspectRatio + textScaler.scale(52) + Insets.sm;

    final Widget content = switch (state) {
      AsyncLoading() => Shimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
          itemBuilder: (_, _) => SizedBox(
            width: itemWidth,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: AnimePoster.aspectRatio,
                  child: SkeletonBox(),
                ),
                SizedBox(height: Insets.sm),
                SkeletonBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      AsyncFailure(:final error) => ErrorView(
        error: error,
        onRetry: onRetry,
        compact: true,
      ),
      AsyncData(:final value) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.md),
        itemBuilder: (context, index) => SizedBox(
          width: itemWidth,
          child: itemBuilder(context, value[index]),
        ),
      ),
    };

    if (state case AsyncData(:final value) when value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        SizedBox(height: height, child: content),
      ],
    );
  }
}

/// Character portrait with name and voice actor.
class CharacterTile extends StatelessWidget {
  const CharacterTile({super.key, required this.character, this.onTap});

  final AnimeCharacter character;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitle = character.voiceActorName ?? character.role;

    return Semantics(
      button: onTap != null,
      label: [
        character.name,
        if (character.role != null) '${character.role} character',
        if (character.voiceActorName != null)
          'voiced by ${character.voiceActorName}',
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: AnimePoster.aspectRatio,
              child: AnimePoster(imageUrl: character.imageUrl),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              character.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle,
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

/// Recommended anime poster with title.
class RecommendationTile extends StatelessWidget {
  const RecommendationTile({
    super.key,
    required this.recommendation,
    required this.onTap,
    this.heroTag,
  });

  final AnimeRecommendation recommendation;
  final VoidCallback onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: recommendation.title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: AnimePoster.aspectRatio,
              child: PosterHero(
                tag: heroTag,
                child: AnimePoster(imageUrl: recommendation.imageUrl),
              ),
            ),
            const SizedBox(height: Insets.xs),
            Text(
              recommendation.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

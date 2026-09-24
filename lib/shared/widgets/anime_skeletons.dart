import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'anime_poster.dart';
import 'shimmer.dart';

/// Placeholder matching [AnimeCard]'s layout.
class AnimeCardSkeleton extends StatelessWidget {
  const AnimeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: AnimePoster.aspectRatio,
          child: SkeletonBox(borderRadius: 10),
        ),
        SizedBox(height: Insets.sm),
        SkeletonBox(height: 12),
        SizedBox(height: Insets.xs),
        FractionallySizedBox(widthFactor: 0.6, child: SkeletonBox(height: 10)),
      ],
    );
  }
}

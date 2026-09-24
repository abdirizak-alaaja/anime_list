import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Compact star + score chip, readable over poster images.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score});

  final double? score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Score ${Formatters.score(score)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.score),
              const SizedBox(width: 2),
              Text(
                Formatters.score(score),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

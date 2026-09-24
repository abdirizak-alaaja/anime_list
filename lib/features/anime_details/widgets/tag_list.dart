import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// A labelled wrap of read-only tags (genres, studios, producers).
class TagList extends StatelessWidget {
  const TagList({
    super.key,
    required this.label,
    required this.tags,
    this.highlight = false,
  });

  final String label;
  final List<String> tags;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final tag in tags)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlight
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: highlight
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

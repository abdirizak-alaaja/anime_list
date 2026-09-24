import 'package:flutter/material.dart';

import '../models/search_sort.dart';

/// Compact sort selector for the results header.
class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.sort,
    required this.onChanged,
    required this.hasText,
  });

  final SearchSort sort;
  final ValueChanged<SearchSort> onChanged;

  /// "Best match" is only offered for text searches.
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final option in SearchSort.values)
        if (option != SearchSort.relevance || hasText) option,
    ];
    final effective = !hasText && sort == SearchSort.relevance
        ? SearchSort.popularity
        : sort;

    return PopupMenuButton<SearchSort>(
      tooltip: 'Sort',
      initialValue: effective,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          CheckedPopupMenuItem(
            value: option,
            checked: option == effective,
            child: Text(option.label),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 18),
            const SizedBox(width: 4),
            Text(
              effective.label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

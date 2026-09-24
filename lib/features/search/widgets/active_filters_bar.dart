import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../models/search_filters.dart';

/// Horizontal row of removable chips for the active filters.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({
    super.key,
    required this.filters,
    required this.genreNames,
    required this.onChanged,
    required this.onClearAll,
  });

  final SearchFilters filters;

  /// Names for selected genre ids; unknown ids fall back to "Genre".
  final Map<int, String> genreNames;
  final ValueChanged<SearchFilters> onChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    final f = filters;
    final chips = <(String, SearchFilters)>[
      if (f.type case final type?) (type.label, f.copyWith(type: () => null)),
      if (f.status case final status?)
        (status.label, f.copyWith(status: () => null)),
      if (f.year case final year?)
        (
          f.season == null ? '$year' : '${f.season!.label} $year',
          f.copyWith(year: () => null),
        ),
      if (f.rating case final rating?)
        (rating.label.split(' ').first, f.copyWith(rating: () => null)),
      if (f.minScore case final score?)
        (
          'Score ${score.toStringAsFixed(1)}+',
          f.copyWith(minScore: () => null),
        ),
      for (final id in f.genreIds)
        (
          genreNames[id] ?? 'Genre',
          f.copyWith(genreIds: {...f.genreIds}..remove(id)),
        ),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
        children: [
          for (final (label, without) in chips)
            Padding(
              padding: const EdgeInsets.only(right: Insets.sm),
              child: InputChip(
                label: Text(label),
                onDeleted: () => onChanged(without),
                deleteButtonTooltipMessage: 'Remove $label filter',
              ),
            ),
          TextButton(onPressed: onClearAll, child: const Text('Clear all')),
        ],
      ),
    );
  }
}

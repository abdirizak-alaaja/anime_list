import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/anime_enums.dart';
import '../../../shared/widgets/message_view.dart';
import '../controllers/anime_search_controller.dart';
import '../models/search_filters.dart';

/// Shows the filter sheet and returns the chosen filters, or `null` if it
/// was dismissed.
Future<SearchFilters?> showFilterSheet(
  BuildContext context, {
  required SearchFilters initial,
  required Future<List<GenreOption>> Function() loadGenres,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 1,
      builder: (context, scrollController) => FilterSheet(
        initial: initial,
        loadGenres: loadGenres,
        scrollController: scrollController,
      ),
    ),
  );
}

/// Edits a draft copy of the filters; nothing changes until "Show results".
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.initial,
    required this.loadGenres,
    this.scrollController,
  });

  final SearchFilters initial;
  final Future<List<GenreOption>> Function() loadGenres;
  final ScrollController? scrollController;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SearchFilters _draft = widget.initial;
  late Future<List<GenreOption>> _genres = widget.loadGenres();

  static final _years = [
    for (var y = DateTime.now().year + 1; y >= 1960; y--) y,
  ];

  void _update(SearchFilters Function(SearchFilters) change) =>
      setState(() => _draft = change(_draft));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
          child: Row(
            children: [
              Expanded(
                child: Text('Filters', style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: _draft.isEmpty
                    ? null
                    : () => setState(() => _draft = SearchFilters.none),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              0,
              Insets.lg,
              Insets.lg,
            ),
            children: [
              _Section(
                title: 'Type',
                child: _EnumChips<AnimeType>(
                  values: AnimeType.values,
                  selected: _draft.type,
                  onSelected: (v) => _update((f) => f.copyWith(type: () => v)),
                ),
              ),
              _Section(
                title: 'Status',
                child: _EnumChips<AnimeStatus>(
                  values: AnimeStatus.values,
                  selected: _draft.status,
                  onSelected: (v) =>
                      _update((f) => f.copyWith(status: () => v)),
                ),
              ),
              _Section(
                title: 'Season',
                child: _SeasonPicker(
                  years: _years,
                  year: _draft.year,
                  season: _draft.season,
                  onYearChanged: (y) =>
                      _update((f) => f.copyWith(year: () => y)),
                  onSeasonChanged: (s) =>
                      _update((f) => f.copyWith(season: () => s)),
                ),
              ),
              _Section(
                title: 'Age rating',
                child: _EnumChips<AnimeRating>(
                  values: AnimeRating.values,
                  selected: _draft.rating,
                  onSelected: (v) =>
                      _update((f) => f.copyWith(rating: () => v)),
                ),
              ),
              _Section(
                title: 'Minimum score',
                trailing: Text(
                  _draft.minScore == null
                      ? 'Any'
                      : '${_draft.minScore!.toStringAsFixed(1)}+',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                child: Slider(
                  value: _draft.minScore ?? 0,
                  max: 9,
                  divisions: 18,
                  label: _draft.minScore == null
                      ? 'Any'
                      : _draft.minScore!.toStringAsFixed(1),
                  onChanged: (v) => _update(
                    (f) => f.copyWith(minScore: () => v == 0 ? null : v),
                  ),
                ),
              ),
              _Section(
                title: 'Genres',
                child: _GenreChips(
                  genres: _genres,
                  selected: _draft.genreIds,
                  onRetry: () => setState(() => _genres = widget.loadGenres()),
                  onChanged: (ids) => _update((f) => f.copyWith(genreIds: ids)),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_draft),
                child: const Text('Show results'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: Insets.sm),
          child,
        ],
      ),
    );
  }
}

/// Single-select chips; tapping the selected chip clears it.
class _EnumChips<T extends ApiValue> extends StatelessWidget {
  const _EnumChips({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<T> values;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value.label),
            selected: value == selected,
            onSelected: (isSelected) => onSelected(isSelected ? value : null),
          ),
      ],
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({
    required this.years,
    required this.year,
    required this.season,
    required this.onYearChanged,
    required this.onSeasonChanged,
  });

  final List<int> years;
  final int? year;
  final AnimeSeason? season;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<AnimeSeason?> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<int?>(
          initialSelection: year,
          label: const Text('Year'),
          width: 180,
          menuHeight: 320,
          onSelected: onYearChanged,
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'Any year'),
            for (final y in years) DropdownMenuEntry(value: y, label: '$y'),
          ],
        ),
        const SizedBox(height: Insets.sm),
        if (year == null)
          Text(
            'Pick a year to filter by season.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          _EnumChips<AnimeSeason>(
            values: AnimeSeason.values,
            selected: season,
            onSelected: onSeasonChanged,
          ),
      ],
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({
    required this.genres,
    required this.selected,
    required this.onChanged,
    required this.onRetry,
  });

  final Future<List<GenreOption>> genres;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: genres,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            error: AppException.from(snapshot.error!),
            onRetry: onRetry,
            compact: true,
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Padding(
            padding: EdgeInsets.all(Insets.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final genre in data)
              FilterChip(
                label: Text(genre.name),
                selected: selected.contains(genre.id),
                onSelected: (isSelected) => onChanged(
                  isSelected
                      ? {...selected, genre.id}
                      : ({...selected}..remove(genre.id)),
                ),
              ),
          ],
        );
      },
    );
  }
}

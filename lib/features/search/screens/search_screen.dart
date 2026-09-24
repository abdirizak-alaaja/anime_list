import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_grid.dart';
import '../controllers/anime_search_controller.dart';
import '../data/recent_searches_store.dart';
import '../repositories/search_repository.dart';
import '../widgets/active_filters_bar.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/recent_searches.dart';
import '../widgets/search_field.dart';
import '../widgets/sort_button.dart';

/// Search tab. Lives in the shell's IndexedStack, so the query, filters and
/// results survive switching tabs and opening details.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final AnimeSearchController _search;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _search = AnimeSearchController(
      searchRepository: SearchRepository(deps.jikan),
      recentSearches: RecentSearchesStore(deps.store),
    );
  }

  @override
  void dispose() {
    _search.recentSearches.dispose();
    _search.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchFor(String term) {
    _textController.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _focusNode.unfocus();
    _search.submit(term);
  }

  void _clearText() {
    _textController.clear();
    _search.clearQuery();
    _focusNode.requestFocus();
  }

  Future<void> _openFilters() async {
    _focusNode.unfocus();
    final filters = await showFilterSheet(
      context,
      initial: _search.filters,
      loadGenres: _search.genres,
    );
    if (filters != null) _search.setFilters(filters);
  }

  void _openAnime(Anime anime) {
    _search.rememberQuery();
    AppRouter.openAnimePreview(context, anime);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _search,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          title: SearchField(
            controller: _textController,
            focusNode: _focusNode,
            onChanged: _search.onQueryChanged,
            onSubmitted: _search.submit,
            onClear: _clearText,
          ),
          actions: [
            IconButton(
              tooltip: 'Filters',
              onPressed: _openFilters,
              icon: Badge.count(
                count: _search.filters.activeCount,
                isLabelVisible: !_search.filters.isEmpty,
                child: const Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(width: Insets.xs),
          ],
        ),
        body: Column(
          children: [
            ActiveFiltersBar(
              filters: _search.filters,
              genreNames: _search.genreNames,
              onChanged: _search.setFilters,
              onClearAll: _search.clearFilters,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_search.hasActiveSearch) {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            RecentSearches(store: _search.recentSearches, onTap: _searchFor),
            Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: OutlinedButton.icon(
                onPressed: _openFilters,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Browse with filters'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _search.refresh,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: _ResultsHeader(search: _search)),
          PagedAnimeSliverGrid(
            controller: _search.results,
            onTap: _openAnime,
            emptyTitle: _search.query.isEmpty
                ? 'No anime match these filters'
                : 'No results for "${_search.query}"',
            emptyMessage: _search.filters.isEmpty
                ? 'Try a different spelling or a shorter title.'
                : 'Try removing a filter.',
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.search});

  final AnimeSearchController search;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: search.results,
      builder: (context, _) {
        final results = search.results;
        final total = results.totalItems;
        final subject = search.query.isEmpty ? '' : ' for "${search.query}"';
        final label = switch (total) {
          final total? => '${Formatters.thousands(total)} results$subject',
          null when results.isLoading => 'Searching…',
          null when results.items.isNotEmpty =>
            '${results.items.length}${results.hasMore ? '+' : ''} results',
          null => '',
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.xs,
            Insets.sm,
            Insets.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SortButton(
                sort: search.sort,
                hasText: search.query.isNotEmpty,
                onChanged: search.setSort,
              ),
            ],
          ),
        );
      },
    );
  }
}

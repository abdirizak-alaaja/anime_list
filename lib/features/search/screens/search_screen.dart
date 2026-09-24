import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/widgets/anime_grid.dart';
import '../controllers/anime_search_controller.dart';
import '../data/recent_searches_store.dart';
import '../repositories/search_repository.dart';
import '../widgets/recent_searches.dart';
import '../widgets/search_field.dart';

/// Search tab. Lives in the shell's IndexedStack, so the query and results
/// survive switching tabs.
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
      repository: SearchRepository(deps.jikan),
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

  void _clear() {
    _textController.clear();
    _search.clear();
    _focusNode.requestFocus();
  }

  void _openAnime(Anime anime) {
    _search.rememberQuery();
    // Navigation to details is wired up with the details screen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: SearchField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: _search.onQueryChanged,
          onSubmitted: _search.submit,
          onClear: _clear,
        ),
      ),
      body: ListenableBuilder(
        listenable: _search,
        builder: (context, _) {
          if (!_search.hasActiveSearch) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: RecentSearches(
                store: _search.recentSearches,
                onTap: _searchFor,
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
                  emptyTitle: 'No results for "${_search.query}"',
                  emptyMessage: 'Try a different spelling or a shorter title.',
                ),
              ],
            ),
          );
        },
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
        final label = switch (total) {
          final total? =>
            '${Formatters.thousands(total)} results for "${search.query}"',
          null when results.isLoading => 'Searching "${search.query}"…',
          null => '',
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.md,
            Insets.lg,
            Insets.md,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

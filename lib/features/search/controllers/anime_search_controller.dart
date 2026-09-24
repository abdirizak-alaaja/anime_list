import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list_controller.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/paginated.dart';
import '../data/recent_searches_store.dart';
import '../models/search_filters.dart';
import '../models/search_sort.dart';
import '../repositories/search_repository.dart';

typedef GenreOption = ({int id, String name});

/// Search state: the committed text query, filters, sort and paged results.
///
/// Typing is debounced and only searches automatically once the query has
/// [minAutoSearchLength] characters; submitting searches immediately.
/// Re-applying an unchanged query/filter/sort combination does nothing, so
/// no duplicate requests are made.
class AnimeSearchController extends ChangeNotifier {
  AnimeSearchController({
    required SearchRepository searchRepository,
    required this.recentSearches,
    Duration debounce = const Duration(milliseconds: 500),
  }) : _repository = searchRepository,
       _debouncer = Debouncer(debounce);

  static const minAutoSearchLength = 3;

  final SearchRepository _repository;
  final RecentSearchesStore recentSearches;
  final Debouncer _debouncer;

  final PagedListController<Anime> results = PagedListController(
    fetchPage: (_, {forceRefresh = false}) async => const Paginated.empty(),
    idOf: (anime) => anime.malId,
  );

  String _query = '';
  SearchFilters _filters = SearchFilters.none;
  SearchSort _sort = SearchSort.relevance;
  Future<List<GenreOption>>? _genres;
  Map<int, String> _genreNames = const {};
  bool _disposed = false;

  /// The text query results are shown for.
  String get query => _query;
  SearchFilters get filters => _filters;
  SearchSort get sort => _sort;

  /// Names of genres loaded so far, for labelling active filter chips.
  Map<int, String> get genreNames => _genreNames;

  /// Whether there is anything to search for: text or at least one filter.
  bool get hasActiveSearch => _query.isNotEmpty || !_filters.isEmpty;

  /// Call on every keystroke.
  void onQueryChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _debouncer.cancel();
      _apply(query: '');
      return;
    }
    if (trimmed.length < minAutoSearchLength) {
      _debouncer.cancel();
      return;
    }
    _debouncer(() => _apply(query: trimmed));
  }

  /// Searches immediately and remembers the term.
  void submit(String text) {
    _debouncer.cancel();
    final trimmed = text.trim();
    _apply(query: trimmed);
    if (trimmed.isNotEmpty) recentSearches.add(trimmed);
  }

  /// Records the current query as a recent search, e.g. when the user opens
  /// one of its results.
  void rememberQuery() {
    if (_query.isNotEmpty) recentSearches.add(_query);
  }

  void clearQuery() {
    _debouncer.cancel();
    _apply(query: '');
  }

  void setFilters(SearchFilters filters) => _apply(filters: filters);

  void clearFilters() => _apply(filters: SearchFilters.none);

  void setSort(SearchSort sort) => _apply(sort: sort);

  Future<void> refresh() => results.refresh();

  /// Genre options for the filter sheet, fetched once and then reused.
  Future<List<GenreOption>> genres() {
    return _genres ??= _repository
        .genres()
        .then((genres) {
          _genreNames = {for (final g in genres) g.id: g.name};
          if (!_disposed) notifyListeners();
          return genres;
        })
        .catchError((Object error) {
          _genres = null; // Allow a retry next time.
          throw error;
        });
  }

  void _apply({String? query, SearchFilters? filters, SearchSort? sort}) {
    final nextQuery = query ?? _query;
    final nextFilters = filters ?? _filters;
    final nextSort = sort ?? _sort;
    if (nextQuery == _query && nextFilters == _filters && nextSort == _sort) {
      return;
    }

    _query = nextQuery;
    _filters = nextFilters;
    _sort = nextSort;

    results.reconfigure(
      fetchPage: _repository.fetcherFor(
        text: _query,
        filters: _filters,
        sort: _sort,
      ),
      sortBy: _filters.usesSeasonalBrowse ? _sort.comparator : null,
    );
    if (hasActiveSearch) results.loadInitial();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debouncer.dispose();
    results.dispose();
    super.dispose();
  }
}

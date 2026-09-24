import 'package:flutter/foundation.dart';

import '../../../core/state/paged_list_controller.dart';
import '../../../core/utils/debouncer.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/anime_query.dart';
import '../data/recent_searches_store.dart';
import '../repositories/search_repository.dart';

/// Search state: the committed query and its paged results.
///
/// Typing is debounced and only searches automatically once the query has
/// [minAutoSearchLength] characters; submitting searches immediately.
/// Re-committing an unchanged query does nothing, so no duplicate requests
/// are made.
class AnimeSearchController extends ChangeNotifier {
  AnimeSearchController({
    required SearchRepository repository,
    required this.recentSearches,
    Duration debounce = const Duration(milliseconds: 500),
  }) : _debouncer = Debouncer(debounce) {
    results = PagedListController<Anime>(
      fetchPage: (page, {forceRefresh = false}) => repository.search(
        AnimeQuery(text: _query),
        page: page,
        forceRefresh: forceRefresh,
      ),
      idOf: (anime) => anime.malId,
    );
  }

  static const minAutoSearchLength = 3;

  final RecentSearchesStore recentSearches;
  final Debouncer _debouncer;
  late final PagedListController<Anime> results;

  String _query = '';

  /// The query results are shown for.
  String get query => _query;

  bool get hasActiveSearch => _query.isNotEmpty;

  /// Call on every keystroke.
  void onQueryChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _debouncer.cancel();
      _commit('');
      return;
    }
    if (trimmed.length < minAutoSearchLength) {
      _debouncer.cancel();
      return;
    }
    _debouncer(() => _commit(trimmed));
  }

  /// Searches immediately and remembers the term.
  void submit(String text) {
    _debouncer.cancel();
    final trimmed = text.trim();
    _commit(trimmed);
    if (trimmed.isNotEmpty) recentSearches.add(trimmed);
  }

  /// Records the current query as a recent search, e.g. when the user opens
  /// one of its results.
  void rememberQuery() {
    if (_query.isNotEmpty) recentSearches.add(_query);
  }

  void clear() {
    _debouncer.cancel();
    _commit('');
  }

  Future<void> refresh() => results.refresh();

  void _commit(String query) {
    if (query == _query) return;
    _query = query;
    results.reset();
    if (query.isNotEmpty) results.loadInitial();
    notifyListeners();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    results.dispose();
    super.dispose();
  }
}

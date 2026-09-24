import 'package:flutter/foundation.dart';

import '../../shared/models/paginated.dart';
import '../errors/app_exception.dart';

typedef PageFetcher<T> = Future<Paginated<T>> Function(
  int page, {
  bool forceRefresh,
});

/// Drives an infinitely scrolling, paginated list.
///
/// - Ignores duplicate load requests while one is running.
/// - Drops duplicate items across pages (Jikan occasionally repeats entries
///   on seasonal endpoints).
/// - Discards responses that arrive after a [reset] or [refresh].
class PagedListController<T> extends ChangeNotifier {
  PagedListController({
    required PageFetcher<T> fetchPage,
    required this.idOf,
    Comparator<T>? sortBy,
  }) : _fetcher = fetchPage,
       _comparator = sortBy;

  PageFetcher<T> _fetcher;
  Comparator<T>? _comparator;
  final Object Function(T item) idOf;

  /// How many consecutive pages without new items are skipped over
  /// automatically before waiting for the user.
  static const _maxEmptyPagesSkipped = 3;

  List<T> _items = const [];
  final Set<Object> _ids = {};
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  int? _totalItems;
  AppException? _error;
  int _generation = 0;
  bool _disposed = false;

  List<T> get items => _items;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  int? get totalItems => _totalItems;

  /// The error from the most recent load, if it failed.
  AppException? get error => _error;

  /// Nothing has been loaded yet (or the list was reset).
  bool get isPristine => _page == 0 && !_isLoading && _error == null;

  bool get isInitialLoading => _isLoading && _items.isEmpty;
  bool get isLoadingMore => _isLoading && _items.isNotEmpty;
  bool get hasLoaded => _page > 0;

  /// Loaded, and there is definitely nothing to show.
  bool get isEmpty =>
      _page > 0 && _items.isEmpty && !_hasMore && _error == null;

  /// Loads the first page if nothing has been loaded yet.
  Future<void> loadInitial() async {
    if (_page > 0 || _isLoading) return;
    await _load(1);
  }

  /// Loads the next page, unless loading, exhausted or in an error state.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _error != null || _page == 0) return;
    await _load(_page + 1);
  }

  /// Retries whichever load last failed.
  Future<void> retry() async {
    if (_isLoading) return;
    _error = null;
    await _load(_page + 1);
  }

  /// Reloads from the first page, bypassing caches. Current items stay
  /// visible until the new page arrives.
  ///
  /// Returns the error if the refresh failed.
  Future<AppException?> refresh() async {
    _generation++;
    await _load(1, forceRefresh: true);
    return _error;
  }

  /// Switches to a different data source (e.g. a new search) and resets.
  ///
  /// [sortBy], when set, keeps the accumulated items sorted client-side.
  void reconfigure({required PageFetcher<T> fetchPage, Comparator<T>? sortBy}) {
    _fetcher = fetchPage;
    _comparator = sortBy;
    reset();
  }

  /// Clears everything and cancels in-flight loads.
  void reset() {
    _generation++;
    _items = const [];
    _ids.clear();
    _page = 0;
    _hasMore = true;
    _isLoading = false;
    _totalItems = null;
    _error = null;
    _notify();
  }

  Future<void> _load(
    int page, {
    bool forceRefresh = false,
    int emptyPagesSkipped = 0,
  }) async {
    final generation = _generation;
    var addedItems = 0;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      final result = await _fetcher(page, forceRefresh: forceRefresh);
      if (_disposed || generation != _generation) return;

      final next = page == 1 ? <T>[] : [..._items];
      if (page == 1) _ids.clear();
      for (final item in result.items) {
        if (_ids.add(idOf(item))) {
          next.add(item);
          addedItems++;
        }
      }
      if (_comparator case final sortBy?) next.sort(sortBy);
      _items = List.unmodifiable(next);
      _page = page;
      _hasMore = result.hasNextPage;
      _totalItems = result.totalItems;
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _error = AppException.from(error);
    } finally {
      if (!_disposed && generation == _generation) {
        _isLoading = false;
        _notify();
      }
    }

    // A page can legitimately contain nothing new (duplicates, or entries
    // removed by client-side filters). Keep going a little so the user isn't
    // left looking at an empty list while more results exist.
    final stale = _disposed || generation != _generation;
    if (!stale &&
        _error == null &&
        addedItems == 0 &&
        _hasMore &&
        emptyPagesSkipped < _maxEmptyPagesSkipped) {
      await _load(_page + 1, emptyPagesSkipped: emptyPagesSkipped + 1);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

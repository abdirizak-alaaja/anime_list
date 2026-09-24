import '../../core/utils/json.dart';

/// One page of results from a paginated Jikan endpoint.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.hasNextPage,
    this.lastVisiblePage,
    this.totalItems,
  });

  const Paginated.empty()
    : items = const [],
      currentPage = 1,
      hasNextPage = false,
      lastVisiblePage = 1,
      totalItems = 0;

  final List<T> items;
  final int currentPage;
  final bool hasNextPage;
  final int? lastVisiblePage;
  final int? totalItems;

  /// Parses `{data: [...], pagination: {...}}`, skipping items that
  /// [parseItem] rejects by returning `null`.
  static Paginated<T> fromJson<T>(
    Json json,
    T? Function(Json item) parseItem, {
    int requestedPage = 1,
  }) {
    final pagination = json.obj('pagination');
    return Paginated(
      items: [for (final item in json.objList('data')) ?parseItem(item)],
      currentPage: pagination?.integer('current_page') ?? requestedPage,
      hasNextPage: pagination?.boolean('has_next_page') ?? false,
      lastVisiblePage: pagination?.integer('last_visible_page'),
      totalItems: pagination?.obj('items')?.integer('total'),
    );
  }
}

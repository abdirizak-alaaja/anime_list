import '../../../core/errors/app_exception.dart';
import '../../../core/state/paged_list_controller.dart';
import '../../../shared/models/anime.dart';
import '../models/discovery_section.dart';
import '../repositories/discovery_repository.dart';

/// Owns one paged list per [DiscoverySection].
class HomeController {
  HomeController(DiscoveryRepository repository)
    : sections = {
        for (final section in DiscoverySection.values)
          section: PagedListController<Anime>(
            fetchPage: (page, {forceRefresh = false}) => repository.fetch(
              section,
              page: page,
              forceRefresh: forceRefresh,
            ),
            idOf: (anime) => anime.malId,
          ),
      };

  final Map<DiscoverySection, PagedListController<Anime>> sections;

  PagedListController<Anime> operator [](DiscoverySection section) =>
      sections[section]!;

  /// Loads every section that hasn't been loaded. Requests are spaced out
  /// by the API client's rate limiter.
  void loadAll() {
    for (final controller in sections.values) {
      controller.loadInitial();
    }
  }

  /// Refreshes all sections; returns the first error, if any.
  Future<AppException?> refreshAll() async {
    final errors = await Future.wait([
      for (final controller in sections.values) controller.refresh(),
    ]);
    return errors.nonNulls.firstOrNull;
  }

  void dispose() {
    for (final controller in sections.values) {
      controller.dispose();
    }
  }
}

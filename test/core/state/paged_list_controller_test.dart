import 'dart:async';

import 'package:anime_list/core/errors/app_exception.dart';
import 'package:anime_list/core/state/paged_list_controller.dart';
import 'package:anime_list/shared/models/paginated.dart';
import 'package:flutter_test/flutter_test.dart';

Paginated<int> page(List<int> items, {bool hasNext = true, int? total}) =>
    Paginated(
      items: items,
      currentPage: 1,
      hasNextPage: hasNext,
      totalItems: total,
    );

void main() {
  test('loads pages in order and stops at the last one', () async {
    final requested = <int>[];
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        requested.add(p);
        return page([p * 10, p * 10 + 1], hasNext: p < 2, total: 4);
      },
      idOf: (i) => i,
    );

    expect(controller.isPristine, isTrue);
    await controller.loadInitial();
    await controller.loadInitial(); // No-op once loaded.
    await controller.loadMore();
    await controller.loadMore(); // Exhausted.

    expect(requested, [1, 2]);
    expect(controller.items, [10, 11, 20, 21]);
    expect(controller.hasMore, isFalse);
    expect(controller.totalItems, 4);
  });

  test('ignores concurrent loads', () async {
    final gate = Completer<Paginated<int>>();
    var calls = 0;
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) {
        calls++;
        return gate.future;
      },
      idOf: (i) => i,
    );

    final first = controller.loadInitial();
    unawaited(controller.loadInitial());
    unawaited(controller.loadMore());
    expect(controller.isInitialLoading, isTrue);
    gate.complete(page([1]));
    await first;
    expect(calls, 1);
  });

  test('drops duplicates across pages', () async {
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async =>
          page(p == 1 ? [1, 2] : [2, 3], hasNext: p == 1),
      idOf: (i) => i,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(controller.items, [1, 2, 3]);
  });

  test('keeps items and exposes the error when a page fails', () async {
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        if (p == 2) throw const NetworkException();
        return page([p]);
      },
      idOf: (i) => i,
    );
    await controller.loadInitial();
    await controller.loadMore();
    expect(controller.items, [1]);
    expect(controller.error, isA<NetworkException>());

    // loadMore is blocked while in error; retry is explicit.
    await controller.loadMore();
    expect(controller.error, isA<NetworkException>());
  });

  test('retry repeats the failed page', () async {
    var fail = true;
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        if (fail) throw const ServerException();
        return page([p], hasNext: false);
      },
      idOf: (i) => i,
    );
    await controller.loadInitial();
    expect(controller.items, isEmpty);
    expect(controller.error, isNotNull);

    fail = false;
    await controller.retry();
    expect(controller.items, [1]);
    expect(controller.error, isNull);
  });

  test('discards responses that arrive after a reset', () async {
    final gate = Completer<Paginated<int>>();
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) => gate.future,
      idOf: (i) => i,
    );
    final load = controller.loadInitial();
    controller.reset();
    gate.complete(page([99]));
    await load;
    expect(controller.items, isEmpty);
    expect(controller.isPristine, isTrue);
  });

  test('refresh bypasses caches and replaces items', () async {
    final forced = <bool>[];
    var generation = 0;
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        forced.add(forceRefresh);
        return page([generation]);
      },
      idOf: (i) => i,
    );
    await controller.loadInitial();
    generation = 1;
    expect(await controller.refresh(), isNull);
    expect(controller.items, [1]);
    expect(forced, [false, true]);
  });

  test('skips a few empty pages automatically', () async {
    final requested = <int>[];
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        requested.add(p);
        return page(p == 3 ? [3] : [], hasNext: p < 10);
      },
      idOf: (i) => i,
    );
    await controller.loadInitial();
    expect(requested, [1, 2, 3]);
    expect(controller.items, [3]);
  });

  test('stops skipping empty pages after the limit', () async {
    final requested = <int>[];
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async {
        requested.add(p);
        return page([], hasNext: true);
      },
      idOf: (i) => i,
    );
    await controller.loadInitial();
    expect(requested, [1, 2, 3, 4]);
    expect(controller.isEmpty, isFalse, reason: 'more pages may match');
    expect(controller.hasLoaded, isTrue);
  });

  test('reconfigure switches source and sorts client-side', () async {
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) async => page([1]),
      idOf: (i) => i,
    );
    await controller.loadInitial();
    controller.reconfigure(
      fetchPage: (p, {forceRefresh = false}) async =>
          page(p == 1 ? [5, 1] : [3], hasNext: p == 1),
      sortBy: (a, b) => a.compareTo(b),
    );
    expect(controller.items, isEmpty);
    await controller.loadInitial();
    await controller.loadMore();
    expect(controller.items, [1, 3, 5]);
  });

  test('does not notify after dispose', () async {
    final gate = Completer<Paginated<int>>();
    final controller = PagedListController<int>(
      fetchPage: (p, {forceRefresh = false}) => gate.future,
      idOf: (i) => i,
    );
    final load = controller.loadInitial();
    controller.dispose();
    gate.complete(page([1]));
    await load; // Must not throw "used after being disposed".
  });
}

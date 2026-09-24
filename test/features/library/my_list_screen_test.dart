import 'package:anime_list/features/library/models/watch_status.dart';
import 'package:anime_list/features/library/screens/my_list_screen.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows an empty state', (tester) async {
    await tester.pumpWidget(testApp(testDependencies(), const MyListScreen()));
    expect(find.text('Your list is empty'), findsOneWidget);
  });

  testWidgets('groups by status and updates progress inline', (tester) async {
    final deps = testDependencies();
    await deps.library.add(
      const Anime(malId: 1, title: 'Planetes', episodes: 26),
      status: WatchStatus.watching,
    );
    await deps.library.add(
      const Anime(malId: 2, title: 'Monster', episodes: 74),
    );

    await tester.pumpWidget(testApp(deps, const MyListScreen()));

    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Watching (1)'), findsOneWidget);
    expect(find.text('Planetes'), findsOneWidget);
    expect(find.text('Monster'), findsOneWidget);

    await tester.tap(find.text('Watching (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Monster'), findsNothing);
    expect(find.text('0 / 26'), findsOneWidget);

    await tester.tap(find.byTooltip('Add an episode'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 26'), findsOneWidget);
    expect(deps.library.entryFor(1)?.episodesWatched, 1);
  });

  testWidgets('swipe removes an entry with undo', (tester) async {
    final deps = testDependencies();
    await deps.library.add(const Anime(malId: 1, title: 'Planetes'));

    await tester.pumpWidget(testApp(deps, const MyListScreen()));
    await tester.drag(find.text('Planetes'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(deps.library.contains(1), isFalse);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(deps.library.contains(1), isTrue);
    expect(find.text('Planetes'), findsOneWidget);
  });

  testWidgets('does not overflow with large text', (tester) async {
    final deps = testDependencies();
    await deps.library.add(
      const Anime(
        malId: 1,
        title: 'A very long anime title that goes on and on and on',
        type: 'TV',
        episodes: 12,
        score: 8.1,
        year: 2020,
      ),
      status: WatchStatus.watching,
    );
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(testApp(deps, const MyListScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

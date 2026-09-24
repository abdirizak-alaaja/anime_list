import 'package:anime_list/features/search/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('searches, shows results and remembers the term', (tester) async {
    final deps = testDependencies(
      handler: (uri) => {
        'pagination': {
          'has_next_page': false,
          'items': {'total': 1},
        },
        'data': [
          {'mal_id': 1, 'title': 'Naruto', 'score': 8.0},
        ],
      },
    );
    await tester.pumpWidget(testApp(deps, const SearchScreen()));
    expect(find.text('Find your next anime'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'naruto');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('1 results for "naruto"'), findsOneWidget);
    expect(find.text('Naruto'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('naruto'), findsOneWidget);
  });

  testWidgets('shows an empty state for no results', (tester) async {
    final deps = testDependencies(
      handler: (_) => {
        'pagination': {'has_next_page': false},
        'data': [],
      },
    );
    await tester.pumpWidget(testApp(deps, const SearchScreen()));
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('No results for "zzzz"'), findsOneWidget);
  });

  testWidgets('filter sheet applies filters as removable chips', (
    tester,
  ) async {
    final deps = testDependencies(
      handler: (uri) => uri.path.contains('genres')
          ? {
              'data': [
                {'mal_id': 1, 'name': 'Action'},
              ],
            }
          : {'data': []},
    );
    await tester.pumpWidget(testApp(deps, const SearchScreen()));

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'Movie'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Movie filter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Movie'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

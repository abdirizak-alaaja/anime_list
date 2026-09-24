import 'package:anime_list/features/anime_details/screens/anime_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('renders full details from Jikan', (tester) async {
    final deps = testDependencies(
      handler: (uri) => uri.path.endsWith('/full')
          ? fixture('anime_full.json')
          : {'data': []},
    );

    await tester.pumpWidget(
      testApp(deps, const AnimeDetailsScreen(malId: 52991)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sousou no Frieren'), findsOneWidget);
    expect(find.text('葬送のフリーレン'), findsOneWidget);
    expect(find.text('Synopsis'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Madhouse'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Madhouse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles sparse data without crashing', (tester) async {
    final deps = testDependencies(
      handler: (uri) => uri.path.endsWith('/full')
          ? {
              'data': {'mal_id': 1, 'title': 'Bare'},
            }
          : {'data': []},
    );

    await tester.pumpWidget(testApp(deps, const AnimeDetailsScreen(malId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Bare'), findsOneWidget);
    expect(find.text('No synopsis available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retryable error when the anime is missing', (
    tester,
  ) async {
    final deps = testDependencies(handler: (_) => null);

    await tester.pumpWidget(testApp(deps, const AnimeDetailsScreen(malId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Not found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

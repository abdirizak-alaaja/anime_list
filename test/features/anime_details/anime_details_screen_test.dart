import 'package:anime_list/features/anime_details/screens/anime_details_screen.dart';
import 'package:anime_list/features/character/screens/character_profile_screen.dart';
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
    expect(find.text('Watch trailer'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Synopsis'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.text('Watch trailer'), findsNothing);
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

  testWidgets('adds the anime to the library and tracks progress', (
    tester,
  ) async {
    final deps = testDependencies(
      handler: (uri) => uri.path.endsWith('/full')
          ? fixture('anime_full.json')
          : {'data': []},
    );
    await tester.pumpWidget(
      testApp(deps, const AnimeDetailsScreen(malId: 52991)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to My List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watching'));
    await tester.pumpAndSettle();

    expect(deps.library.entryFor(52991)?.status.label, 'Watching');
    expect(find.text('0 / 28'), findsOneWidget);

    await tester.tap(find.byTooltip('Add an episode'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 28'), findsOneWidget);
    expect(deps.library.entryFor(52991)?.episodesWatched, 1);
  });

  testWidgets('opens a character profile from the cast', (tester) async {
    final deps = testDependencies(
      handler: (uri) => switch (uri.path) {
        final p when p.endsWith('/full') && p.contains('/characters/') =>
          fixture('character_full.json'),
        final p when p.endsWith('/full') => fixture('anime_full.json'),
        final p when p.endsWith('/characters') => {
          'data': [
            {
              'role': 'Main',
              'character': {'mal_id': 184947, 'name': 'Frieren'},
            },
          ],
        },
        _ => {'data': []},
      },
    );
    await tester.pumpWidget(
      testApp(deps, const AnimeDetailsScreen(malId: 52991)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Frieren'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Frieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frieren'));
    await tester.pumpAndSettle();

    expect(find.byType(CharacterProfileScreen), findsOneWidget);
    expect(find.text('フリーレン'), findsOneWidget);
  });
}

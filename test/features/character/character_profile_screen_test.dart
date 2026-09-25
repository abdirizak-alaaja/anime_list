import 'package:anime_list/features/anime_details/screens/anime_details_screen.dart';
import 'package:anime_list/features/character/screens/character_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows the profile and opens an anime from it', (tester) async {
    final deps = testDependencies(
      handler: (uri) => switch (uri.path) {
        final p when p.endsWith('/characters/184947/full') => fixture(
          'character_full.json',
        ),
        final p when p.endsWith('/anime/52991/full') => fixture(
          'anime_full.json',
        ),
        _ => {'data': []},
      },
    );

    await tester.pumpWidget(
      testApp(deps, const CharacterProfileScreen(malId: 184947)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frieren'), findsWidgets);
    expect(find.text('フリーレン'), findsOneWidget);
    expect(find.text('51,234 favorites'), findsOneWidget);
    expect(find.textContaining('elf mage'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Tanezaki, Atsumi'),
      300,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(
      find.text('Sousou no Frieren'),
      300,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('Sousou no Frieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sousou no Frieren'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error when the character is missing', (tester) async {
    final deps = testDependencies(handler: (_) => null);

    await tester.pumpWidget(
      testApp(deps, const CharacterProfileScreen(malId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

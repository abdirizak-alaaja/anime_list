import 'package:anime_list/features/favorites/screens/favorites_screen.dart';
import 'package:anime_list/shared/models/anime.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows an empty state', (tester) async {
    await tester.pumpWidget(
      testApp(testDependencies(), const FavoritesScreen()),
    );
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('lists favorites and removes with undo', (tester) async {
    final deps = testDependencies();
    await deps.favorites.add(const Anime(malId: 1, title: 'Mushishi'));

    await tester.pumpWidget(testApp(deps, const FavoritesScreen()));
    expect(find.text('Mushishi'), findsOneWidget);
    expect(find.text('Favorites (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Mushishi'), findsOneWidget);
  });
}

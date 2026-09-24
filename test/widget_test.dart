import 'dart:convert';

import 'package:anime_list/app.dart';
import 'package:anime_list/core/di/app_dependencies.dart';
import 'package:anime_list/core/network/jikan_http_client.dart';
import 'package:anime_list/core/network/rate_limiter.dart';
import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:anime_list/features/anime_details/screens/anime_details_screen.dart';
import 'package:anime_list/shared/widgets/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('app starts in dark mode on the Discover tab', (tester) async {
    final deps = AppDependencies(
      store: InMemoryKeyValueStore(),
      httpClient: JikanHttpClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {'mal_id': 1, 'title': 'Test Anime', 'score': 8.5},
              ],
            }),
            200,
          ),
        ),
        rateLimiter: RateLimiter(limits: const []),
      ),
    );
    await tester.pumpWidget(AnimeListApp(dependencies: deps));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
    expect(find.text('Test Anime'), findsWidgets);
  });

  testWidgets('opening an anime shown in several carousels', (tester) async {
    // Every section returns the same anime, so each carousel shows it; the
    // hero transition must still work with one poster per section.
    final deps = testDependencies(
      handler: (uri) => uri.path.endsWith('/full')
          ? {
              'data': {'mal_id': 1, 'title': 'Test Anime', 'episodes': 12},
            }
          : {
              'data': [
                {'mal_id': 1, 'title': 'Test Anime', 'score': 8.5},
              ],
            },
    );
    await tester.pumpWidget(AnimeListApp(dependencies: deps));
    await tester.pumpAndSettle();

    final card = find.byType(AnimeCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AnimeDetailsScreen), findsOneWidget);
    expect(find.text('Add to My List'), findsOneWidget);
  });
}

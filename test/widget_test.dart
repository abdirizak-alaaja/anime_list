import 'package:anime_list/app.dart';
import 'package:anime_list/core/di/app_dependencies.dart';
import 'package:anime_list/core/storage/key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts in dark mode with bottom navigation', (tester) async {
    final deps = AppDependencies(store: InMemoryKeyValueStore());
    await tester.pumpWidget(AnimeListApp(dependencies: deps));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('My List'), findsOneWidget);
  });
}

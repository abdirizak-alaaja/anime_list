import 'package:anime_list/core/network/api_health.dart';
import 'package:anime_list/shared/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('appears while offline and hides on recovery', (tester) async {
    final health = ApiHealth();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineBanner(health: health)),
      ),
    );
    expect(find.textContaining("You're offline"), findsNothing);

    health.reportOffline();
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);

    health.reportSuccess();
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
  });
}

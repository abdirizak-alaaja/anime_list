import 'package:anime_list/shared/widgets/about_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the developer info', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AboutButton())),
      ),
    );

    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();
    expect(find.text('Abdirizak Abdullahi (Alaaja)'), findsOneWidget);
    expect(find.text('Studies at Somali International University'), findsOne);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}

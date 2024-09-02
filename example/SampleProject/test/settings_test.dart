import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Settings icon button is clickable', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pump();
  });
}

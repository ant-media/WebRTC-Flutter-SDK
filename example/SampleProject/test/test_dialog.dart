import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Server address dialog is shown', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Check if the dialog is shown with the correct title
    expect(find.text('Enter Stream Address using the following format:'),
        findsOneWidget);
  });
}

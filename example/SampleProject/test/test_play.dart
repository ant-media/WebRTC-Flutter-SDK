import 'dart:async';

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Runs the app, taps on the settings icon, and enters the URL',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: MyApp(),
    )));

    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    final Finder textFieldFinder = find.byType(TextField);
    await tester.enterText(
        textFieldFinder, 'ws://test.antmedia.io:5443/24x7test/');
    expect(
        find.widgetWithText(MaterialButton, 'Set Server Ip'), findsOneWidget);
    expect(
        find
            .widgetWithText(MaterialButton, 'Set Server Ip')
            .evaluate()
            .first
            .widget,
        isA<MaterialButton>().having((b) => b.enabled, 'enabled', true));

    final Finder setServerIpButtonFinder =
        find.widgetWithText(MaterialButton, 'Set Server Ip');
    expect(setServerIpButtonFinder, findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(setServerIpButtonFinder);
    await tester.pumpAndSettle();
  });
}

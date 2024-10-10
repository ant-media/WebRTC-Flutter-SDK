// test_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/main.dart';

// A helper method to launch the app.
Future<void> launchApp(WidgetTester tester) async {
  // Mock initial values for shared preferences.
  SharedPreferences.setMockInitialValues({});

  // Launch the app.
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(
      body: MyApp(),
    ),
  ));
  await tester.pumpAndSettle();
}

// A helper method to open settings and enter a server URL.
Future<void> enterServerUrl(WidgetTester tester, String url) async {
  // Verify the settings icon is present.
  expect(find.byIcon(Icons.settings), findsOneWidget);

  // Tap the settings icon.
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  // Check if the AlertDialog appears after tapping settings.
  expect(find.byType(AlertDialog), findsOneWidget);

  // Enter the server URL in the TextField inside the dialog.
  await tester.enterText(find.byType(TextField), url);
  await tester.pumpAndSettle();

  // Tap the "Set Server Ip" button.
  final setServerIpButton = find.widgetWithText(MaterialButton, 'Set Server Ip');
  expect(setServerIpButton, findsOneWidget);
  await tester.tap(setServerIpButton);
  await tester.pumpAndSettle();

  // Verify that a SnackBar appears after setting the server IP.
  expect(find.byType(SnackBar), findsOneWidget);
}

// A helper method to enter a Room ID and tap OK.
Future<void> enterRoomId(WidgetTester tester, String roomId) async {
  await tester.enterText(find.byType(TextField), roomId);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
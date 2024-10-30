// publish_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/publish.dart';
import 'test_helper.dart';

void main() {
  // Initialize the integration test bindings.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Runs the app, taps on the settings icon, enters the URL, and runs the Conference example', (WidgetTester tester) async {
    // Launch the app.
    await launchApp(tester);

    // Enter the server URL.
    await enterServerUrl(tester, 'wss://test.antmedia.io:5443/FlutterCICDtest/websocket');


    // Tap the 'Conference' button.
    await tester.tap(find.text('Conference'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Find the first text field and enter 'test'.
    await tester.enterText(find.byType(TextField).at(0), 'test');
    await tester.pumpAndSettle();

    // Find the second text field and enter 'room'.
    await tester.enterText(find.byType(TextField).at(1), 'room');
    await tester.pumpAndSettle();

    // Tap the 'Connect' button.
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });
}

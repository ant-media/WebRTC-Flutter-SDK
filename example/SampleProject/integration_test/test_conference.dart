// publish_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/publish.dart';
import 'test_helper.dart';

void main() {
  // Initialize the integration test bindings.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Runs the app, taps on the settings icon, enters the URL, and runs the Publish example', (WidgetTester tester) async {
    // Launch the app.
    await launchApp(tester);

    // Enter the server URL.
    await enterServerUrl(tester, 'wss://test.antmedia.io:5443/testFilip/websocket');

    // Tap the 'Publish' button.
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Enter Room ID and tap OK.
    await enterRoomId(tester, 'publishTest');

    // Verify the AlertDialog to choose the publishing source appears.
    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap the "Camera" button.
    await tester.tap(find.widgetWithText(MaterialButton, 'Camera'));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Verify that the Publish screen is loaded.
    expect(find.byType(Publish), findsOneWidget);

    // Check if the call_end icon is present and tap it if it appears.
    final callEndIcon = find.byIcon(Icons.call_end);
    await tester.tap(callEndIcon);
    await tester.pumpAndSettle();
  });
}

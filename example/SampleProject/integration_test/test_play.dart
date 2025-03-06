import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helper.dart';

void main() {
  // Initialize the integration test bindings.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Runs the app, taps on the settings icon, enters the URL, and runs the play example', (WidgetTester tester) async {
    // Launch the app.
    await launchApp(tester);

    await tester.pumpAndSettle();

    // Enter the server URL.
    await enterServerUrl(tester, 'wss://test.antmedia.io:5443/24x7test/websocket');

    await tester.pumpAndSettle();

    // Tap the 'Play' button.
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    // Enter Room ID and tap OK.
    await enterRoomId(tester, '24x7test');
    await tester.pumpAndSettle(const Duration(seconds: 60));

    // Verify the content of the SnackBar.
    final callEndIcon = find.byIcon(Icons.call_end);
    await tester.tap(callEndIcon);
    await tester.pumpAndSettle();
  });
}

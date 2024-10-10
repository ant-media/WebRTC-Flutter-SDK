import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/main.dart';

void main() {
  // Initialize the integration test bindings.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Runs the app, taps on the settings icon, enters the URL, and runs the Peer to Peer example', (WidgetTester tester) async {
    // Mock initial values for shared preferences.
    SharedPreferences.setMockInitialValues({});

    // Launch the app.
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: MyApp(),
        )));

    // Ensure the app has built.
    await tester.pumpAndSettle();

    // Verify the settings icon is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Tap the settings icon.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Check if the AlertDialog appears after tapping settings.
    expect(find.byType(AlertDialog), findsOneWidget);

    // Enter the server URL in the TextField inside the dialog.
    await tester.enterText(find.byType(TextField), 'wss://test.antmedia.io:5443/24x7test/websocket');
    await tester.pumpAndSettle();

    // Ensure the "Set Server Ip" button is present and enabled.
    final setServerIpButton = find.widgetWithText(MaterialButton, 'Set Server Ip');
    expect(setServerIpButton, findsOneWidget);

    // Tap the "Set Server Ip" button.
    await tester.tap(setServerIpButton);
    await tester.pumpAndSettle();

    // Verify that a SnackBar appears after setting the server IP.
    expect(find.byType(SnackBar), findsOneWidget);

    // Tap the 'Conference' button.
    await tester.tap(find.text('Peer to Peer'));
    await tester.pumpAndSettle();

    // Enter Room ID and tap OK.
    await tester.enterText(find.byType(TextField), '24x7test');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}

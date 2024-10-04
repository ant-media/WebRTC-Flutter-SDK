import 'package:example/publish.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example/main.dart';

void main() {
  // Initialize the integration test bindings.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Runs the app, taps on the settings icon, enters the URL, and runs the Publish example', (WidgetTester tester) async {
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
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify that a SnackBar appears after setting the server IP.
    expect(find.byType(SnackBar), findsOneWidget);

    // Tap the 'Publish' button.
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Enter Room ID and tap OK.
    await tester.enterText(find.byType(TextField), 'publishTest');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Check if the AlertDialog to choose the publishing source appears.
    expect(find.byType(AlertDialog), findsOneWidget);

    // Tap the "Camera" button.
    await tester.tap(find.widgetWithText(MaterialButton, 'Camera'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that the Publish screen is loaded.
    expect(find.byType(Publish), findsOneWidget);

    // Check if the call_end icon is present and tap it if it appears.
    final callEndIcon = find.byIcon(Icons.call_end);
    await tester.tap(callEndIcon);
    await tester.pumpAndSettle();
  });
}

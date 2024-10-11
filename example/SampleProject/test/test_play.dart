import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Runs the app, taps on the settings icon, and enters the URL, then runs the play example',
          (WidgetTester tester) async {

        // Mock initial values for shared preferences.
        SharedPreferences.setMockInitialValues({});

        // Pump the MyApp widget inside a MaterialApp and Scaffold.
        await tester.pumpWidget(const MaterialApp(
            home: Scaffold(
              body: MyApp(),
            )));

        // Verify the settings icon is present on the screen.
        expect(find.byIcon(Icons.settings), findsOneWidget);

        // Log the number of settings icons found in the UI.
        print("Number of settings icons found: ${find.byIcon(Icons.settings).evaluate().length}");

        // Tap the settings icon and wait for the app to settle.
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Verify that an AlertDialog appears after tapping the settings icon.
        expect(find.byType(AlertDialog), findsOneWidget);

        // Find the TextField inside the dialog and enter the server URL.
        final Finder textFieldFinder = find.byType(TextField);
        await tester.enterText(
            textFieldFinder, 'wss://test.antmedia.io:5443/24x7test/websocket');

        // Verify that the "Set Server Ip" button is present and enabled.
        expect(
            find.widgetWithText(MaterialButton, 'Set Server Ip'), findsOneWidget);
        expect(
            find
                .widgetWithText(MaterialButton, 'Set Server Ip')
                .evaluate()
                .first
                .widget,
            isA<MaterialButton>().having((b) => b.enabled, 'enabled', true));

        // Locate the "Set Server Ip" button and tap it.
        final Finder setServerIpButtonFinder =
        find.widgetWithText(MaterialButton, 'Set Server Ip');
        expect(setServerIpButtonFinder, findsOneWidget);
        await tester.pumpAndSettle();

        // Tap the button and wait for the app to settle.
        await tester.runAsync(() async => tester.tap(setServerIpButtonFinder));
        await tester.runAsync(() async => tester.pumpAndSettle());

        // Verify that a SnackBar appears after setting the server IP.
        expect(find.byType(SnackBar), findsOneWidget);

        // Ensure the 'Play' text is in the widget tree.
        expect(find.text('Play'), findsOneWidget);

        // Tap the 'Play' button.
        await tester.tap(find.text('Play'));

        // Log that the Play button was tapped.
        print("Tapped Play button");

        // Rebuild the widget after the tap.
        await tester.pumpAndSettle();

        // Check if the Room ID dialog is displayed (this is part of the navigation flow).
        expect(find.text("Enter Room ID"), findsOneWidget);

        // Enter a Room ID in the TextField.
        await tester.enterText(find.byType(TextField), '24x7test');

        // Tap the 'OK' button to confirm the Room ID.
        await tester.tap(find.text('OK'));

        // Rebuild the widget after the dialog is closed.
        await tester.pumpAndSettle();
      });
}

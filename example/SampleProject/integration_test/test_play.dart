import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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

    await tester.pumpAndSettle();
    expect(find.byType(RTCVideoView), findsOneWidget);

    final rtcVideoViewFinder = find.byType(RTCVideoView);
    expect(rtcVideoViewFinder, findsOneWidget);

    final rtcVideoView = tester.widget<RTCVideoView>(rtcVideoViewFinder);
    RTCVideoRenderer renderer = rtcVideoView.videoRenderer;

    const maxWaitTime = Duration(seconds: 67);
    final stopwatch = Stopwatch()..start();

    while (renderer.videoWidth == 0 || renderer.videoHeight == 0) {
      if (stopwatch.elapsed > maxWaitTime) {
        fail('RTCVideoRenderer did not start playing within 45 seconds');
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  });
}

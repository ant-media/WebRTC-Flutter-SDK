import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    // Ensure Flutter bindings are initialized before the tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set up a mock response to handle method calls
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        // Return mock permission statuses
        return {
          Permission.camera.value: PermissionStatus.granted.index,
          Permission.microphone.value: PermissionStatus.granted.index,
          Permission.bluetooth.value: PermissionStatus.granted.index,
        };
      }
      return null;
    });
  });

  tearDown(() {
    // Reset the mock handler after each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('should request permissions for camera, microphone, and bluetooth', () async {
    // Call the method that requests permissions
    final statusCamera = await Permission.camera.request();
    final statusMicrophone = await Permission.microphone.request();
    final statusBluetooth = await Permission.bluetooth.request();

    // Verify that permissions were granted
    expect(statusCamera, PermissionStatus.granted);
    expect(statusMicrophone, PermissionStatus.granted);
    expect(statusBluetooth, PermissionStatus.granted);
  });
}

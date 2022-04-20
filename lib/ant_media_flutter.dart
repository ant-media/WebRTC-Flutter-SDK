import 'dart:async';

import 'package:ant_media_flutter/src/call_sample/call_sample.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';

class AntMediaFlutter {
  static const MethodChannel _channel = MethodChannel('ant_media_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

static void requestPermissions() {
  Permission.camera.request().then((value) => 
  Permission.microphone.request().then((value) =>  
  Permission.bluetoothConnect.request().then((value) => null)));
}

  static void publishWith(
      String id, bool userscreen, String server, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CallSample(
                  ip: server,
                  type: 'publish',
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void playWith(String id, String server,  bool userscreen ,BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CallSample(
                  ip: server,
                  type: 'play',
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void starPeerConnectionwithStreamId(String id, String server, bool userscreen ,BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => CallSample(
                  ip: server,
                  type: 'p2p',
                  id: id,
                  userscreen: userscreen,
                )));
  }

 static Future<bool> startForegroundService() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Title of the notification',
      notificationText: 'Text of the notification',
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon:
          AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);
    return FlutterBackground.enableBackgroundExecution();
  }

}

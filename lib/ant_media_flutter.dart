import 'dart:async';

import 'package:ant_media_flutter/src/modules/conference.dart';
import 'package:ant_media_flutter/src/modules/datachannel.dart';
import 'package:ant_media_flutter/src/modules/peer.dart';
import 'package:ant_media_flutter/src/modules/play.dart';
import 'package:ant_media_flutter/src/modules/publish.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';

class AntMediaFlutter {
  static const MethodChannel _channel = MethodChannel('ant_media_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static void requestPermissions() {
    Permission.camera.request().then((value) => Permission.microphone
        .request()
        .then((value) =>
            Permission.bluetoothConnect.request().then((value) => null)));
  }

  static void publishWith(
      String id, bool userscreen, String server, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => PublishCallSample(
                  ip: server,
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void startDataChannelWith(
      String id, bool userscreen, String server, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => DataChannelSample(
                  ip: server,
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void playWith(
      String id, String server, bool userscreen, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => PlaySample(
                  ip: server,
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void starPeerConnectionwithStreamId(
      String id, String server, bool userscreen, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => PeerSample(
                  ip: server,
                  id: id,
                  userscreen: userscreen,
                )));
  }

  static void startConferenceWithStreamId(String id, String roomId,
      String server, bool userscreen, BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => ConferenceCall(
                  ip: server,
                  id: id,
                  userscreen: userscreen,
                  roomId: roomId,
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

// ignore_for_file: prefer_generic_function_type_aliases, constant_identifier_names

import 'dart:async';

import 'package:ant_media_flutter/src/helpers/helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

// HelperState is used to determine the state of the websocket connection between the device and the Ant Media Server
enum HelperState {
  CallStateNew,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

// AntMedia Media Types is used to determine different modes of Ant Media Server
enum AntMediaType { Default, Publish, Play, Peer, Conference, DataChannelOnly }

typedef void HelperStateCallback(HelperState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);
typedef void DataChannelMessageCallback(
    RTCDataChannel dc, RTCDataChannelMessage data, bool isReceived);
typedef void DataChannelCallback(RTCDataChannel dc);
typedef void ConferenceUpdateCallback(dynamic streams);
typedef void Callbacks(String command, Map mapData);

class DataChannelMessage extends Object {
  RTCDataChannelMessage message;
  bool isRecieved;
  RTCDataChannel channel;
  DataChannelMessage(this.isRecieved, this.channel, this.message);
}

class AntMediaFlutter {
  static AntHelper? anthelper;

  // requestPermissions is used to request permissions for camera, microphone and bluetoothConnect
  static void requestPermissions() {
    Permission.camera
        .request()
        .then((value) => Permission.microphone.request().then((value) => {
              if (value.isGranted && !kIsWeb)
                {Permission.bluetoothConnect.request().then((value) => null)}
            }));
  }

  // startForegroundService is used to start the background service for the app
  // it should be called on the Android platform
  static Future<bool> startForegroundService() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Title of the notification',
      notificationText: 'Text of the notification',
      notificationIcon:
          AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    try {
      await FlutterBackground.initialize(androidConfig: androidConfig);
      try {
        await FlutterBackground.enableBackgroundExecution();
      } catch (e) {
      }

      bool initialized = await FlutterBackground.initialize(androidConfig: androidConfig);
      if (initialized) {
        await FlutterBackground.enableBackgroundExecution();
        return true;
      } else {
        print('Error: FlutterBackground not initialized');
        return false;
      }
    } catch (e) {
      print('Error initializing FlutterBackground: $e');
      return false;
    }
  }

  // connect is the entry point for the plugin
  // it is used to connect to the Ant Media Server
  static void connect(
      String ip,
      String streamId,
      String roomId,
      String token,
      AntMediaType type,
      bool userScreen,
      HelperStateCallback onStateChange,
      StreamStateCallback onLocalStream,
      StreamStateCallback onAddRemoteStream,
      DataChannelCallback onDataChannel,
      DataChannelMessageCallback onDataChannelMessage,
      ConferenceUpdateCallback onupdateConferencePerson,
      StreamStateCallback onRemoveRemoteStream,
      List<Map<String, String>> iceServers,
      Callbacks callbacks) async {
    anthelper = null;
    anthelper ??= AntHelper(
      // automatically start the service
        true,

        //host
        ip,

        //streamID
        streamId,

        //roomID
        roomId,

        //token
        token,

        //onStateChange
        onStateChange,

        //onAddRemoteStream
        onAddRemoteStream,

        //onDataChannel
        onDataChannel,

        //onDataChannelMessage
        onDataChannelMessage,

        //onLocalStream
        onLocalStream,

        //onRemoveRemoteStream
        onRemoveRemoteStream,

        //ScreenSharing
        userScreen,

        // onupdateConferencePerson
        onupdateConferencePerson,

        //iceServers
        iceServers,

        //callbacks
        callbacks)
      ..connect(type);
  }

  // prepare is the entry point for the plugin
  static void prepare(
      String ip,
      String streamId,
      String roomId,
      String token,
      AntMediaType type,
      bool userScreen,
      HelperStateCallback onStateChange,
      StreamStateCallback onLocalStream,
      StreamStateCallback onAddRemoteStream,
      DataChannelCallback onDataChannel,
      DataChannelMessageCallback onDataChannelMessage,
      ConferenceUpdateCallback onupdateConferencePerson,
      StreamStateCallback onRemoveRemoteStream,
      List<Map<String, String>> iceServers,
      Callbacks callbacks) async {
    anthelper = null;
    anthelper ??= AntHelper(
      // automatically start the service
      false,

      //host
        ip,

        //streamID
        streamId,

        //roomID
        roomId,

        //token
        token,

        //onStateChange
        onStateChange,

        //onAddRemoteStream
        onAddRemoteStream,

        //onDataChannel
        onDataChannel,

        //onDataChannelMessage
        onDataChannelMessage,

        //onLocalStream
        onLocalStream,

        //onRemoveRemoteStream
        onRemoveRemoteStream,

        //ScreenSharing
        userScreen,

        // onupdateConferencePerson
        onupdateConferencePerson,

        //iceServers
        iceServers,

        //callbacks
        callbacks)
      ..connect(type);
  }
}

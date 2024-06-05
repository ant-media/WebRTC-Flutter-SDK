// ignore_for_file: prefer_generic_function_type_aliases, constant_identifier_names

import 'dart:async';

import 'package:ant_media_flutter/src/helpers/adaptor.dart';
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
  static Adaptor? adaptor;

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
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon:
          AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);
    return FlutterBackground.enableBackgroundExecution();
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

  // connect is the entry point for the plugin
  // it is used to connect to the Ant Media Server
  static void initialize({
    webSocketUrl = "wss://antmedia.io:5443/WebRTCAppEE/websocket",
    roomName,
    isPlayMode = false,
    debug = false,
    onlyDataChannel = false,
    dataChannelEnabled = true,
    candidateTypes = const ["udp", "tcp"],
    callback,
    callbackError,
    iceServers = const [
      {'url': 'stun:stun.l.google.com:19302'},
    ],
    sdpConstraints = const {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    },
  }) async {
    adaptor = null;
    adaptor ??= Adaptor(
      webSocketUrl: webSocketUrl,
      roomName: roomName,
      isPlayMode: isPlayMode,
      debug: debug,
      onlyDataChannel: onlyDataChannel,
      dataChannelEnabled: dataChannelEnabled,
      candidateTypes: candidateTypes,
      callback: callback,
      callbackError: callbackError,
      iceServers: iceServers,
      sdpConstraints: sdpConstraints,
    );
  }
}

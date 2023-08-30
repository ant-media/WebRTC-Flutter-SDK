// ignore_for_file: must_be_immutable

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:ant_media_flutter/src/helpers/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:core';

class PlayWidget extends StatefulWidget {
  String ip;
  String id;
  String roomId;
  bool userscreen;

  PlayWidget(
      {Key? key,
      required this.ip,
      required this.id,
      required this.roomId,
      required this.userscreen})
      : super(key: key);

  @override
  _PlayWidgetState createState() => _PlayWidgetState();
}

class _PlayWidgetState extends State<PlayWidget> {
  AntHelper? _anthelper;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;

  _PlayWidgetState();

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_anthelper != null) _anthelper?.close();

    _remoteRenderer.dispose();
  }

  void _connect() async {
    _anthelper ??= AntHelper(

        //host
        widget.ip,

        //streamID
        widget.id,

        //roomID
        widget.roomId,

        //onStateChange
        (HelperState state) {
          switch (state) {
            case HelperState.CallStateNew:
              setState(() {
                _inCalling = true;
              });
              break;
            case HelperState.CallStateBye:
              setState(() {
                _remoteRenderer.srcObject = null;
                _inCalling = false;
                Navigator.pop(context);
              });
              break;
            case HelperState.ConnectionClosed:
            case HelperState.ConnectionError:
            case HelperState.ConnectionOpen:
              break;
          }
        },

        //onAddRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }),

        // onDataChannel
        (stream) {},

        // onDataChannelMessage
        (stream, message, channel) {},

        //onLocalStream
        ((stream) {
          setState(() {});
        }),

        //onRemoveRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = null;
          });
        }),
        //ScreenSharing
        widget.userscreen,
        (streams) {},

        [{"url": "stun:stun.l.google.com:19302"}],
            (command , mapData){

        })
      ..connect(AntMediaType.Play);
  }

  @override
  Widget build(BuildContext context) {
    return _inCalling
        ? Positioned(
            child: Container(
            margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ))
        : Container();
  }
}

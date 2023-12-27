// ignore_for_file: must_be_immutable, implementation_imports

import 'dart:core';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:ant_media_flutter/src/utils/conference_widget/playwidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Conference extends StatefulWidget {
  static String tag = 'call';

  String ip;
  String id;
  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];
  String roomId;
  bool userscreen;

  Conference(
      {Key? key,
      required this.ip,
      required this.id,
      required this.roomId,
      required this.userscreen})
      : super(key: key);

  @override
  _ConferenceState createState() => _ConferenceState();
}

class _ConferenceState extends State<Conference> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  List<Widget> widgets = [];
  bool _inCalling = false;

  _ConferenceState();

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (AntMediaFlutter.anthelper != null) AntMediaFlutter.anthelper?.close();
    _localRenderer.dispose();
  }

  void _connect() async {
    AntMediaFlutter.connect(
        //host
        widget.ip,
        //streamID
        widget.id,
        //roomID
        widget.roomId,
        AntMediaType.Conference,
        widget.userscreen,

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
                _localRenderer.srcObject = null;
                _inCalling = false;
                Navigator.pop(context);
              });
              break;
            case HelperState.ConnectionOpen:
              break;
            case HelperState.ConnectionClosed:
              break;
            case HelperState.ConnectionError:
              break;
          }
        },

        //onLocalStream
        ((stream) {
          setState(() {
            _localRenderer.srcObject = stream;
          });
        }),

        //onAddRemoteStream
        ((stream) {}),

        // onDataChannel
        (dc) {},
        (dc, message, isReceived) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              (isReceived ? "Received:" : "Sent:") + " " + message.text,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
          ));
        },

        //onUpdateConferenceUser
        (streams) {
          List<Widget> widgetlist = [];
          for (final stream in streams) {
            SizedBox widget = SizedBox(
              child: PlayWidget(
                  ip: this.widget.ip,
                  id: stream,
                  roomId: this.widget.roomId,
                  userscreen: false),
            );
            widgetlist.add(widget);
          }

          setState(() {
            widgets = widgetlist;
          });
        },

        //onRemoveRemoteStream
        ((stream) {
          setState(() {});
        }),
        widget.iceServers,
        (command, mapData) {});
  }

  _hangUp() {
    if (AntMediaFlutter.anthelper != null) {
      AntMediaFlutter.anthelper?.bye();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Conferencing'),
          actions: const <Widget>[],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? SizedBox(
                width: 200.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FloatingActionButton(
                        heroTag: "btn2",
                        onPressed: _hangUp,
                        tooltip: 'Hangup',
                        child: const Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                    ]))
            : null,
        body: OrientationBuilder(builder: (context, orientation) {
          Widget local = SizedBox(
            child: RTCVideoView(_localRenderer),
          );

          List<Widget> widgetlist = [local] + widgets;

          return GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            children: widgetlist,
          );
        }));
  }
}

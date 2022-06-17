// ignore_for_file: must_be_immutable

import 'dart:core';

import 'package:ant_media_flutter/src/utils/conference_widget/playwidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../helpers/helper2.dart';

class ConferenceCall extends StatefulWidget {
  static String tag = 'call_sample';

  String ip;
  String id;
  String roomId;
  bool userscreen;

  ConferenceCall(
      {Key? key,
      required this.ip,
      required this.id,
      required this.roomId,
      required this.userscreen})
      : super(key: key);

  @override
  _ConferenceCallState createState() => _ConferenceCallState();
}

class _ConferenceCallState extends State<ConferenceCall> {
  AntHelper2? _AntHelper2;
  List<dynamic> _peers = [];
  String? _selfId;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  List<Widget> widgets = [];
  bool _inCalling = false;
  bool _micOn = true;

  _ConferenceCallState();

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
    if (_AntHelper2 != null) _AntHelper2?.close();
    _localRenderer.dispose();
  }

  void _connect() async {
    _AntHelper2 ??= AntHelper2(

        //host
        widget.ip,

        //streamID
        widget.id,

        //roomID
        widget.roomId,

        //onStateChange
        (Helper2State state) {
          switch (state) {
            case Helper2State.CallStateNew:
              setState(() {
                _inCalling = true;
              });
              break;
            case Helper2State.CallStateBye:
              setState(() {
                _localRenderer.srcObject = null;
                _inCalling = false;
                Navigator.pop(context);
              });
              break;

            case Helper2State.CallStateInvite:

            case Helper2State.CallStateConnected:

            case Helper2State.CallStateRinging:

            case Helper2State.ConnectionClosed:

            case Helper2State.ConnectionError:

            case Helper2State.ConnectionOpen:
              break;
          }
        },

        //onAddRemoteStream
        ((stream) {}),

        // onDataChannel
        (stream) {},

        // onDataChannelMessage
        (stream, channel) {},

        //onLocalStream
        ((stream) {
          setState(() {
            _localRenderer.srcObject = stream;
          });
        }),

        //onPeersUpdate
        ((event) {
          setState(() {
            _selfId = event['self'];
            _peers = event['peers'];
          });
        }),

        //onRemoveRemoteStream
        ((stream) {
          setState(() {});
        }),
        //ScreenSharing
        widget.userscreen,

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

          widgets = widgetlist;

          setState(() {});
        })
      ..connect();
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_AntHelper2 != null && peerId != _selfId) {
      _AntHelper2?.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    if (_AntHelper2 != null) {
      _AntHelper2?.bye();
    }
  }

  _switchCamera() {
    _AntHelper2?.switchCamera();
  }

  _muteMic(bool state) {
    if (_micOn) {
      setState(() {
        _AntHelper2?.muteMic(true);
        _micOn = false;
      });
    } else {
      setState(() {
        _AntHelper2?.muteMic(false);
        _micOn = true;
      });
    }
  }

  _buildRow(context, peer) {
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self
            ? peer['name'] + '[Your self]'
            : peer['name'] + '[' + peer['user_agent'] + ']'),
        onTap: null,
        trailing: SizedBox(
            width: 100.0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () => _invitePeer(context, peer['id'], false),
                    tooltip: 'Video calling',
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_share),
                    onPressed: () => _invitePeer(context, peer['id'], true),
                    tooltip: 'Screen sharing',
                  )
                ])),
        subtitle: Text('id: ' + peer['id']),
      ),
      const Divider()
    ]);
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
                    // FloatingActionButton(
                    //   heroTag: "btn1",
                    //   child: const Icon(Icons.switch_camera),
                    //   onPressed: _switchCamera,
                    // ),
                    FloatingActionButton(
                      heroTag: "btn2",
                      onPressed: _hangUp,
                      tooltip: 'Hangup',
                      child: const Icon(Icons.call_end),
                      backgroundColor: Colors.pink,
                    ),
                    // FloatingActionButton(
                    //   heroTag: "btn3",
                    //   child: const Icon(Icons.mic_off),
                    //   onPressed: _muteMic,
                    // )
                  ]))
          : null,
      body: _inCalling
          ? OrientationBuilder(builder: (context, orientation) {
              Widget local = SizedBox(
                child: RTCVideoView(_localRenderer),
              );

              List<Widget> widgetlist = [local] + widgets;

              return GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                children: widgetlist,
              );
            })
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: (_peers.length),
              itemBuilder: (context, i) {
                return _buildRow(context, _peers[i]);
              }),
    );
  }
}

// ignore_for_file: must_be_immutable

import 'dart:core';

import 'package:ant_media_flutter/src/helpers/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Play extends StatefulWidget {
  String ip;
  String id;
  bool userscreen;

  Play({Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _PlayState createState() => _PlayState();
}

class _PlayState extends State<Play> {
  AntHelper3? _AntHelper3;
  List<dynamic> _peers = [];
  String? _selfId;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;

  _PlayState();

  late SharedPreferences _prefs;

  @override
  initState() {
    super.initState();
    _initData();
    initRenderers();
    _connect();
  }

  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs.setString('type', "publish");
    });
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_AntHelper3 != null) _AntHelper3?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    _AntHelper3 ??= AntHelper3(
      //host
      widget.ip,

      //streamID
      widget.id,

      //roomID
      '',

      //onStateChange
      (Helper3State state) {
        switch (state) {
          case Helper3State.CallStateNew:
            setState(() {
              _inCalling = true;
            });
            break;
          case Helper3State.CallStateBye:
            setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _inCalling = false;
              Navigator.pop(context);
            });
            break;
          case Helper3State.CallStateInvite:
          case Helper3State.CallStateConnected:
          case Helper3State.CallStateRinging:
          case Helper3State.ConnectionClosed:
          case Helper3State.ConnectionError:
          case Helper3State.ConnectionOpen:
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
      (stream, channel) {},

      //onLocalStream
      ((stream) {
        setState(() {
          _remoteRenderer.srcObject = stream;
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
        setState(() {
          _remoteRenderer.srcObject = null;
        });
      }),
      //ScreenSharing
      widget.userscreen,

      // onConference
      (stream) {},
    )..connect("play");
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_AntHelper3 != null && peerId != _selfId) {
      _AntHelper3?.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    _AntHelper3?.bye();
  }

  _switchCamera() {
    //_AntHelper3?.switchCamera();
  }

  _muteMic() {
    _AntHelper3?.muteMic(false);
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
        title: const Text('Playing'),
        actions: const <Widget>[],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling
          ? SizedBox(
              width: 200.0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
      body: _inCalling
          ? OrientationBuilder(builder: (context, orientation) {
              return Stack(children: <Widget>[
                Positioned(
                    left: 0.0,
                    right: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: RTCVideoView(_remoteRenderer),
                      decoration: const BoxDecoration(color: Colors.black54),
                    )),
              ]);
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

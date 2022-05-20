// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:core';
import 'signaling.dart';

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
  Signaling? _signaling;
  List<dynamic> _peers = [];
  String? _selfId;
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
    if (_signaling != null) _signaling?.close();

    _remoteRenderer.dispose();
  }

  void _connect() async {
    _signaling ??= Signaling(

        //host
        widget.ip,

        //type
        'play',

        //streamID
        widget.id,

        //roomID
        widget.roomId,

        //onStateChange
        (SignalingState state) {
          switch (state) {
            case SignalingState.CallStateNew:
              setState(() {
                _inCalling = true;
              });
              break;
            case SignalingState.CallStateBye:
              setState(() {
                _remoteRenderer.srcObject = null;
                _inCalling = false;
                Navigator.pop(context);
              });
              break;
            case SignalingState.CallStateInvite:
            case SignalingState.CallStateConnected:
            case SignalingState.CallStateRinging:
            case SignalingState.ConnectionClosed:
            case SignalingState.ConnectionError:
            case SignalingState.ConnectionOpen:
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
          setState(() {});
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
        widget.userscreen)
      ..connect();
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling?.invite(peerId, 'video', useScreen);
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
    return _inCalling
        ? 
             Positioned(
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
            
         
        : ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0.0),
            itemCount: (_peers.length),
            itemBuilder: (context, i) {
              return _buildRow(context, _peers[i]);
            });
  }
}

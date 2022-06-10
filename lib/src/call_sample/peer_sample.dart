// ignore_for_file: must_be_immutable

import 'package:ant_media_flutter/src/call_sample/peer_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:core';
import 'signaling.dart';

class PeerSample extends StatefulWidget {
  String ip;
  String id;
  bool userscreen;

  PeerSample(
      {Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _PeerSampleState createState() => _PeerSampleState();
}

class _PeerSampleState extends State<PeerSample> {
  PeerHelper? _peerHelper;
  List<dynamic> _peers = [];
  String? _selfId;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  bool _micOn = true;

  _PeerSampleState();

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_peerHelper != null) _peerHelper?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    _peerHelper ??= PeerHelper(

        //host
        widget.ip,

        //streamID
        widget.id,

        //roomID
        '',

        //onStateChange
        (PeerHelperState state) {
          switch (state) {
            case PeerHelperState.CallStateNew:
              setState(() {
                _inCalling = true;
              });
              break;
            case PeerHelperState.CallStateBye:
              setState(() {
                _localRenderer.srcObject = null;
                _remoteRenderer.srcObject = null;
                _inCalling = false;
                Navigator.pop(context);
              });
              break;
            case PeerHelperState.CallStateInvite:
            case PeerHelperState.CallStateConnected:
            case PeerHelperState.CallStateRinging:
            case PeerHelperState.ConnectionClosed:
            case PeerHelperState.ConnectionError:
            case PeerHelperState.ConnectionOpen:
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
        widget.userscreen)
      ..connect();
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_peerHelper != null && peerId != _selfId) {
      _peerHelper?.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    _peerHelper?.disconnectPeer();
  }

  _switchCamera() {
    _peerHelper?.switchCamera();
  }

  _muteMic(bool state) {
    if (_micOn) {
      setState(() {
        _peerHelper?.muteMic(true);
        _micOn = false;
      });
    } else {
      setState(() {
        _peerHelper?.muteMic(false);
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
        title: const Text('Peer to Peer'),
        actions: const <Widget>[],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling
          ? SizedBox(
              width: 200.0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FloatingActionButton(
                      heroTag: "btn1",
                      child: const Icon(Icons.switch_camera),
                      onPressed: _switchCamera,
                    ),
                    FloatingActionButton(
                      heroTag: "btn2",
                      onPressed: _hangUp,
                      tooltip: 'Hangup',
                      child: const Icon(Icons.call_end),
                      backgroundColor: Colors.pink,
                    ),
                    FloatingActionButton(
                        heroTag: "btn3",
                        // backgroundColor: _micOn ? null : Theme.of(context).disabledColor,
                        tooltip: _micOn == true ? 'Stop mic' : 'Start mic',
                        //onPressed: _micOn==true ? _muteMic(false) : _muteMic(true),
                        onPressed: () => _muteMic(_micOn),
                        child:
                            Icon(_micOn == false ? Icons.mic : Icons.mic_off)),
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

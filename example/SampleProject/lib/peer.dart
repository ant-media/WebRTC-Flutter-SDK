// ignore_for_file: must_be_immutable, non_constant_identifier_names

import 'dart:core';
import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Peer extends StatefulWidget {
  String ip;
  String id;
  bool userscreen;
  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];

  Peer({Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _PeerState createState() => _PeerState();
}

class _PeerState extends State<Peer> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  bool _micOn = true;

  MediaStream? local_input_stream;

  _PeerState();

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
    if (AntMediaFlutter.anthelper != null) AntMediaFlutter.anthelper?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    AntMediaFlutter.connect(
        //host
        widget.ip,
//streamID
        widget.id,
        //roomID
        '',
        //token
        '',
        AntMediaType.Peer,
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

        //onLocalStream
        ((stream) {
          setState(() {
            _localRenderer.srcObject = stream;
            local_input_stream = stream;
          });
        }),

        //onAddRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }),

        // onDataChannel
        (dc) {},

        //onDataChannelMessage

        (dc, message, isReceived) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              (isReceived ? "Received:" : "Sent:") + " " + message.text,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
          ));
        },

        // onupdateConferencePerson

        (Streams) {},

        //onRemoveRemoteStream
        (stream) {
          setState(() {
            _remoteRenderer.srcObject = null;
          });
        },
        widget.iceServers,
        (command, mapData) {});
  }

  _hangUp() {
    AntMediaFlutter.anthelper?.disconnectPeer();
  }

  _switchCamera() {
    AntMediaFlutter.anthelper?.switchCamera();
  }

  _muteMic(bool state) {
    if (_micOn) {
      setState(() {
        AntMediaFlutter.anthelper?.muteMic(true);
        _micOn = false;
      });
    } else {
      setState(() {
        AntMediaFlutter.anthelper?.muteMic(false);
        _micOn = true;
      });
    }
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
                          child: Icon(
                              _micOn == false ? Icons.mic : Icons.mic_off)),
                    ]))
            : null,
        body: OrientationBuilder(builder: (context, orientation) {
          return _inCalling
              ? Stack(children: <Widget>[
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
                  Positioned(
                      right: 20.0,
                      top: 20.0,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        width: 50,
                        height: 100,
                        child: RTCVideoView(_localRenderer),
                        decoration: const BoxDecoration(color: Colors.black54),
                      )),
                ])
              : Container();
        }));
  }
}

// ignore_for_file: must_be_immutable, avoid_print

import 'dart:core';
import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Publish extends StatefulWidget {
  static String tag = 'call';

  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];

  String ip;
  String id;
  bool userscreen;

  Publish(
      {Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _PublishState createState() => _PublishState();
}

class _PublishState extends State<Publish> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  bool _micOn = true;
  bool _camOn = true;
  _PublishState();

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
        AntMediaType.Publish,
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
            _remoteRenderer.srcObject = stream;
          });
        }),

        //onAddRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }),

        // onDataChannel
        (datachannel) {
          print(datachannel.id);
          print(datachannel.state);
        },

        // onDataChannelMessage
        (channel, message, isReceived) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              (isReceived ? "Received:" : "Sent:") + " " + message.text,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
          ));
        },

        // onupdateConferencePerson
        (streams) {},

        //onRemoveRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = null;
          });
        }),
        widget.iceServers,
        (command, mapData) {});
  }

  _hangUp() {
    if (AntMediaFlutter.anthelper != null) {
      AntMediaFlutter.anthelper?.bye();
    }
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

  _toggleCam(bool state) {
    if (_camOn) {
      setState(() {
        AntMediaFlutter.anthelper?.toggleCam(false);
        _camOn = false;
      });
    } else {
      setState(() {
        AntMediaFlutter.anthelper?.toggleCam(true);
        _camOn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Publishing'),
          actions: const <Widget>[],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? SizedBox(
                width: 300.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.userscreen == false)
                        FloatingActionButton(
                          heroTag: "btn1",
                          child: const Icon(Icons.switch_camera),
                          onPressed: _switchCamera,
                        ),
                      const SizedBox(
                        width: 10,
                      ),
                      FloatingActionButton(
                        heroTag: "btn2",
                        onPressed: _hangUp,
                        tooltip: 'Hangup',
                        child: const Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      if (widget.userscreen == false)
                        FloatingActionButton(
                            heroTag: "btn3",
                            tooltip: _micOn == true ? 'Stop Mic' : 'Start Mic',
                            onPressed: () => _muteMic(_micOn),
                            child: Icon(
                                _micOn == false ? Icons.mic : Icons.mic_off)),
                      const SizedBox(
                        width: 10,
                      ),
                      FloatingActionButton(
                          heroTag: "btn4",
                          tooltip:
                              _camOn == true ? 'Stop Camera' : 'Start Camera',
                          onPressed: () => _toggleCam(_camOn),
                          child: Icon(_camOn == true
                              ? Icons.videocam
                              : Icons.videocam_off)),
                    ]))
            : null,
        body: OrientationBuilder(builder: (context, orientation) {
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
                  child: (widget.userscreen)
                      ? const Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Screen is sharing',
                            ),
                          ),
                        )
                      : RTCVideoView(_remoteRenderer),
                  decoration: const BoxDecoration(color: Colors.black54),
                )),
          ]);
        }));
  }
}

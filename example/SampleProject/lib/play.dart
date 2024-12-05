// ignore_for_file: must_be_immutable, avoid_print

import 'dart:core';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Play extends StatefulWidget {
  String ip;
  String id;
  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];
  bool userscreen;

  Play({Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _PlayState createState() => _PlayState();
}

class _PlayState extends State<Play> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  List<String> abrList = ['Automatic'];
  bool _inCalling = false;
  bool _isPaused = false;

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
        AntMediaType.Play,
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
                _isPaused ? _isPaused : Navigator.pop(context);
                // Navigator.pop(context);
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
        (stream) {},

        //onRemoveRemoteStream
        ((stream) {
          setState(() {
            _remoteRenderer.srcObject = null;
          });
        }),
        widget.iceServers,
        (command, mapData) {
          abrList = ['Automatic'];
          if (command == 'streamInformation') {
            print(mapData['streamInfo']);
            setState(() {
              mapData['streamInfo'].forEach((abrSetting) =>
                  {abrList.add(abrSetting['streamHeight'].toString())});
            });
          }
        });
  }

  _hangUp() {
    AntMediaFlutter.anthelper?.bye();
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
                        backgroundColor: Colors.pink,
                        child: const Icon(Icons.call_end),
                      ),
                      DropdownButton<String>(
                        items: abrList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (streamHeight) {
                          if (streamHeight == 'Automatic') streamHeight = '0';
                          AntMediaFlutter.anthelper?.forceStreamQuality(
                              widget.id, int?.parse(streamHeight.toString()));
                        },
                      )
                    ]))
            : null,
        body: OrientationBuilder(
          builder: (context, orientation) {
            return Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(color: Colors.black54),
                  child: RTCVideoView(_remoteRenderer),
                ),
                _isPaused
                    ? Center(
                  child: FloatingActionButton(
                    heroTag: "btn3",
                    onPressed: () {
                      setState(() {
                        _isPaused = false;
                      });
                      _connect();
                    },
                    tooltip: 'Play',
                    backgroundColor: Colors.grey.withOpacity(0.6),
                    child: const Icon(Icons.play_arrow),
                  ),
                )
                    : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPaused = true;
                    });
                    _hangUp();
                  },
                  child: Container(
                    color: Colors.transparent, // Makes the entire screen tappable
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.pause,
                      color: Colors.transparent, // Keeps the icon invisible
                    ),
                  ),
                ),
              ],
            );
          },
        )
    );
  }

}

// ignore_for_file: must_be_immutable, avoid_print

import 'dart:core';
import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class DataChannel extends StatefulWidget {
  String ip;
  String id;
  bool userscreen;

  DataChannel(
      {Key? key, required this.ip, required this.id, required this.userscreen})
      : super(key: key);

  @override
  _DataChannelState createState() => _DataChannelState();
}

class _DataChannelState extends State<DataChannel> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  List<DataChannelMessage> messages = [];

  _DataChannelState();

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

      //type
      AntMediaType.DataChannelOnly,

      //userScreen
      false,

      //forDataChannel
      true,

      //onStateChange
          (HelperState state) {
        switch (state) {
          case HelperState.CallStateNew:
            setState(() {});
            break;
          case HelperState.CallStateBye:
            setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
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
        print('');
      },

      // onDataChannelMessage
          (channel, message, isRecieved) {
        messages.add(DataChannelMessage(isRecieved, channel, message));
        setState(() {});
      },

      // onupdateConferencePerson
          (stream) {},

      //onRemoveRemoteStream
      ((stream) {
        setState(() {
          _remoteRenderer.srcObject = null;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Data Channel'),
          actions: const <Widget>[],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            List<Widget> textmessages = [];

            for (DataChannelMessage datachannelmessage in messages) {
              textmessages.add(Text(
                (datachannelmessage.isRecieved ? 'Received: ' : 'Sent: ') +
                    datachannelmessage.message.text +
                    ' ',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: (Colors.black),
                  fontSize: 22,
                ),
              ));
            }

            return Stack(children: <Widget>[
              Positioned(
                  left: 20.0,
                  bottom: 100.0,
                  right: 20.0,
                  top: 20,
                  child: ListView(children: textmessages)),
              Positioned(
                  left: 20.0,
                  bottom: 20.0,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: MediaQuery.of(context).size.width - 100,
                    height: 50,
                    child: textfield,
                  )),
              Positioned(
                right: 20.0,
                bottom: 20.0,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                  width: 50,
                  height: 50,
                  child: IconButton(
                    onPressed: () async {
                      RTCDataChannelMessage message = RTCDataChannelMessage(
                          textfield.controller?.text ?? '');
                      await AntMediaFlutter.anthelper?.sendMessage(message);
                      textfield.controller?.clear();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
              )
            ]);
          },
        ));
  }

  TextField textfield = TextField(
    controller: TextEditingController(),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      hintText: 'Type here....',
      fillColor: Colors.white,
    ),
  );
}

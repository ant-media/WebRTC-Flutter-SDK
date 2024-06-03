// ignore_for_file: must_be_immutable

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class PlayWidget extends StatefulWidget {
  final MediaStream roomMediaStream;
  final String roomId;

  const PlayWidget(
      {Key? key, required this.roomMediaStream, required this.roomId})
      : super(key: key);

  @override
  PlayWidgetState createState() => PlayWidgetState();
}

class PlayWidgetState extends State<PlayWidget> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderer();
  }

  Future<void> initRenderer() async {
    await _remoteRenderer.initialize();
    print('initRenderer');
    print(widget.roomMediaStream);
    _remoteRenderer.srcObject = widget.roomMediaStream;
    setState(() {});
  }

  @override
  void deactivate() {
    _remoteRenderer.dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
        child: RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          placeholderBuilder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}

// ignore_for_file: must_be_immutable non_constant_identifier_names, unnecessary_this, curly_braces_in_flow_control_structures, unnecessary_new, avoid_print, prefer_const_constructors, constant_identifier_names, prefer_collection_literals, prefer_generic_function_type_aliases, prefer_final_fields, unnecessary_string_interpolations, prefer_interpolation_to_compose_strings

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

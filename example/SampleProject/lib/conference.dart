// ignore_for_file: must_be_immutable, implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:ui' show FontFeature;

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:ant_media_flutter/src/utils/conference_widget/playwidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class Conference extends StatefulWidget {
  static String tag = 'call';

  String ip;
  String id;
  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];
  String roomId;
  bool userscreen;

  Conference(
      {Key? key,
      required this.ip,
      required this.id,
      required this.roomId,
      required this.userscreen})
      : super(key: key);

  @override
  _ConferenceState createState() => _ConferenceState();
}

class _ConferenceState extends State<Conference> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  // Remote video tracks as they arrive, keyed by WebRTC track id.
  final Map<String, MediaStreamTrack> _videoTracks = {};

  // On-screen tiles, keyed by the participant's AMS track id. AMS pushes the
  // authoritative roster on the data channel as VIDEO_TRACK_ASSIGNMENT_LIST;
  // stream.getVideoTracks() only ever grows and never reflects leavers.
  Map<String, MediaStream> _tiles = {};
  List<dynamic> _assignments = const [];
  bool _inCalling = false;

  // Demo controls + live stats overlay
  bool _micOn = true;
  bool _camOn = true;
  Timer? _statsTimer;
  // Per-track byte counters, so each participant's rate is independent.
  final Map<String, int> _lastBytesByTrack = {};
  Map<String, String> _tileStats = {};
  DateTime? _lastStatsAt;
  bool _loggedStatKeys = false;

  _ConferenceState();

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
    _statsTimer?.cancel();
    if (AntMediaFlutter.anthelper != null) AntMediaFlutter.anthelper?.close();
    _localRenderer.dispose();
  }

  // Map a WebRTC track identifier back to the participant that owns it, via
  // the same videoLabel suffix match the tiles use.
  String? _participantForTrack(String trackKey) {
    for (final a in _assignments) {
      if (a is! Map) continue;
      final label = a['videoLabel'] as String?;
      final pid = a['trackId'] as String?;
      if (label != null && pid != null && trackKey.endsWith(label)) return pid;
    }
    return null;
  }

  // Poll inbound video stats per participant so the demo can show each
  // participant's quality adapting independently.
  void _startStats() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final reports =
          await AntMediaFlutter.anthelper?.getStats(widget.roomId) ?? [];
      final now = DateTime.now();
      final secs = _lastStatsAt == null
          ? 0.0
          : now.difference(_lastStatsAt!).inMilliseconds / 1000.0;

      final next = <String, String>{};

      for (final r in reports) {
        if (r.type != 'inbound-rtp' || r.values['kind'] != 'video') continue;
        final v = r.values;

        if (!_loggedStatKeys) {
          _loggedStatKeys = true;
          print('inbound-rtp video keys: ${v.keys.toList()}');
          print('inbound-rtp video sample: $v');
        }

        final trackKey =
            (v['trackIdentifier'] ?? v['trackId'] ?? r.id).toString();
        final bytes = (v['bytesReceived'] as num?)?.toInt() ?? 0;
        final prev = _lastBytesByTrack[trackKey];
        var kbps = 0;
        if (prev != null && secs > 0) {
          kbps = ((bytes - prev) * 8 / 1000 / secs).round();
        }
        _lastBytesByTrack[trackKey] = bytes;

        final pid = _participantForTrack(trackKey);
        if (pid == null) continue;
        final w = (v['frameWidth'] as num?)?.toInt() ?? 0;
        final h = (v['frameHeight'] as num?)?.toInt() ?? 0;
        next[pid] = (w > 0 ? '${w}x$h  ' : '') + '$kbps kbps';
      }

      _lastStatsAt = now;
      if (!mounted) return;
      setState(() => _tileStats = next);
    });
  }

  // Rebuild the tile list from the latest assignment list. Adds tiles for
  // joiners, drops and disposes tiles for leavers.
  Future<void> _applyAssignments() async {
    final next = <String, MediaStream>{};
    for (final a in _assignments) {
      final label = a['videoLabel'] as String?;
      final pid = a['trackId'] as String?;
      if (label == null || pid == null) continue;

      // AMS labels tracks "videoTrack0"; the WebRTC id is "ARDAMSvvideoTrack0".
      MediaStreamTrack? track;
      for (final t in _videoTracks.values) {
        if ((t.id ?? '').endsWith(label)) {
          track = t;
          break;
        }
      }
      if (track == null) continue;

      var stream = _tiles[pid];
      if (stream == null) {
        stream = await createLocalMediaStream(pid);
        await stream.addTrack(track);
      }
      next[pid] = stream;
    }

    for (final entry in _tiles.entries) {
      if (!next.containsKey(entry.key)) entry.value.dispose();
    }

    if (!mounted) return;
    setState(() => _tiles = next);
  }

  void _toggleMic() {
    setState(() => _micOn = !_micOn);
    AntMediaFlutter.anthelper?.muteMic(!_micOn);
  }

  void _toggleCam() {
    setState(() => _camOn = !_camOn);
    AntMediaFlutter.anthelper?.toggleCam(_camOn);
  }

  void _connect() async {
    AntMediaFlutter.connect(
        //host
        widget.ip,
        //streamID
        widget.id,
        //roomID
        widget.roomId,
        //token
        "",
        AntMediaType.Conference,
        widget.userscreen,

        //onStateChange
        (HelperState state) {
          switch (state) {
            case HelperState.CallStateNew:
              setState(() {
                _inCalling = true;
              });
              _startStats();
              break;
            case HelperState.CallStateBye:
              setState(() {
                _localRenderer.srcObject = null;
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
            _localRenderer.srcObject = stream;
          });
        }),

        //onAddRemoteStream
        ((stream) {
          setState(() {});
        }),

        // onDataChannel
        (dc) {},
        (dc, message, isReceived) {
          try {
            JsonDecoder decoder = const JsonDecoder();
            Map<String, dynamic> map = decoder.convert(message.text);
            if (map['eventType'] != "UPDATE_AUDIO_LEVEL") {
              print("DataChannelMessage: $map");
            }
            if (map['eventType'] == "VIDEO_TRACK_ASSIGNMENT_LIST") {
              _assignments = (map['payload'] as List?) ?? const [];
              _applyAssignments();
            }
            if (map['eventType'] == "TRACK_LIST_UPDATED") {
              // AMS does not push a new assignment list on leave; ask for it.
              AntMediaFlutter.anthelper
                  ?.requestVideoTrackAssignments(widget.roomId);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                "${isReceived ? "Received:" : "Sent:"} ${message.text}",
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
            ));
          }
        },

        //onUpdateConferenceUser
        (streams) async {
          for (final t in streams.getVideoTracks()) {
            final id = t.id;
            if (id != null) _videoTracks[id] = t;
          }
          await _applyAssignments();
        },

        //onRemoveRemoteStream
        ((stream) {
          setState(() {});
        }),
        widget.iceServers,
        (command, mapData) {
          if (command == 'notification' &&
              mapData['definition'] == 'subtrackRemoved') {
            final gone = mapData['trackId'];
            if (gone != null) {
              _assignments = _assignments
                  .where((a) => a is Map && a['trackId'] != gone)
                  .toList();
              _applyAssignments();
            }
          }
          // AMS answers requestVideoTrackAssignments over the websocket.
          if (command == 'videoTrackAssignmentList') {
            final list = (mapData['videoTrackAssignments'] ??
                mapData['payload']) as List?;
            if (list != null) {
              _assignments = list;
              _applyAssignments();
            }
          }
          print("Inside conference.dart");
          print("Command: $command");
          print("Data: $mapData");
        });
  }

  _hangUp() {
    if (AntMediaFlutter.anthelper != null) {
      AntMediaFlutter.anthelper?.bye();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Conferencing'),
          backgroundColor: const Color(0xFF007BFF),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: const <Widget>[],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? SizedBox(
                width: 260.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FloatingActionButton(
                        heroTag: "btnMic",
                        onPressed: _toggleMic,
                        tooltip: _micOn ? 'Mute mic' : 'Unmute mic',
                        backgroundColor: _micOn ? Colors.blueGrey : Colors.red,
                        child: Icon(_micOn ? Icons.mic : Icons.mic_off),
                      ),
                      FloatingActionButton(
                        heroTag: "btnCam",
                        onPressed: _toggleCam,
                        tooltip: _camOn ? 'Turn camera off' : 'Turn camera on',
                        backgroundColor: _camOn ? Colors.blueGrey : Colors.red,
                        child: Icon(
                            _camOn ? Icons.videocam : Icons.videocam_off),
                      ),
                      FloatingActionButton(
                        heroTag: "btn2",
                        onPressed: _hangUp,
                        tooltip: 'Hangup',
                        child: const Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                    ]))
            : null,
        backgroundColor: const Color(0xFFF7F7F9),
        body: OrientationBuilder(builder: (context, orientation) {
          // Card + centred caption, mirroring conference.html's player tiles.
          Widget tile(Widget video, String label) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: const Color(0xFF212529),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      video,
                      Positioned(
                        top: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1.3,
                                  fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

          final cells = <Widget>[
            tile(
              RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
              'You',
            ),
            ..._tiles.entries.map((e) => tile(
                  PlayWidget(
                    key: ValueKey(e.key),
                    roomMediaStream: e.value,
                    roomId: widget.roomId,
                  ),
                  _tileStats[e.key] == null
                      ? e.key
                      : '${e.key}\n${_tileStats[e.key]}',
                )),
          ];

          return Stack(
            children: [
              GridView.count(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 4 / 3,
                children: cells,
              ),
            ],
          );
        }));
  }
}

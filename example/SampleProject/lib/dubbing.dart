import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> makeRestRequest() async {
  final url = Uri.parse('https://ovh36.antmedia.io/WebRTCAppEE/rest/v2/filters/create');
  final headers = {
    'Accept': 'Application/json',
    'Content-Type': 'application/json',
  };
  final body = jsonEncode({
    'inputStreams': ['test', 'stream1'],
    'outputStreams': ['output${DateTime.now().millisecondsSinceEpoch}'],
    'videoFilter': '[in0]copy[out0]',
    'audioFilter': '[in1]acopy[out0]',
    'videoEnabled': 'true',
    'audioEnabled': 'true',
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    print('Request successful: ${response.body}');
  } else {
    print('Request failed with status: ${response.statusCode}');
  }
}

class HLSWebRTCApp extends StatefulWidget {
  @override
  _HLSWebRTCAppState createState() => _HLSWebRTCAppState();
}

class _HLSWebRTCAppState extends State<HLSWebRTCApp> {
  late VideoPlayerController _videoController;
  late MediaStream _audioStream;
  late MediaStream _combinedStream;
  static String tag = 'call';
  bool isStarted = false;

  String ip = "wss://ovh36.antmedia.io/WebRTCAppEE/websocket";
  String id = "stream1";
  bool userscreen = false;
  List<Map<String, String>> iceServers = [
    {'url': 'stun:stun.l.google.com:19302'},
  ];

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  bool _micOn = true;

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
    _videoController = VideoPlayerController.network(
      'https://fe.tring.al/delta/105/out/u/1200_1.m3u8',
    )..initialize().then((_) {
      setState(() {});
      _videoController.setLooping(true);
      //_videoController.play();
    });

    /*
    getMicrophoneStream().then((stream) {
      _audioStream = stream;
      combineStreams(_videoController, _audioStream).then((combinedStream) {
        _combinedStream = combinedStream;
        publishStream(_combinedStream);
      });
    });

     */
    //_connect();
  }

  Future<void> _prepareAndMakeRequest() async {
    // Perform any necessary asynchronous preparations here
    // For example, ensuring a stable network connection, gathering additional data, etc.

    // Introduce a delay
    await Future.delayed(Duration(seconds: 3)); // Adjust the duration as needed

    // Now call makeRestRequest
    await makeRestRequest();
    _videoController.play();
  }

  void _connect() async {
    AntMediaFlutter.connect(
      //host
        ip,

        //streamID
        id,

        //roomID
        '',

        //token
        '',
        AntMediaType.Publish,
        userscreen,

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
              _prepareAndMakeRequest();
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
        iceServers,
            (command, mapData) {});
  }

  _hangUp() {
    if (AntMediaFlutter.anthelper != null) {
      AntMediaFlutter.anthelper?.bye();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioStream.dispose();
    _combinedStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HLS WebRTC App')),
      body: Center(
        child: _videoController.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        )
            : const CircularProgressIndicator(),
      ),
      bottomSheet: ButtonBar(
        alignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(onPressed: () => {
            if (isStarted) {
              _hangUp(),
              _videoController.pause()
            } else {
              _connect(),
              _videoController.play()
            },
            setState(() {
              isStarted = !isStarted;
            })
          }, child: Text(isStarted ? 'Stop' : 'Start'))
        ],
      )
    );
  }
}

void main() {
  runApp(MaterialApp(home: HLSWebRTCApp()));
}

Future<MediaStream> getMicrophoneStream() async {
  final mediaConstraints = {
    'audio': true,
    'video': false,
  };
  MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  return stream;
}

Future<MediaStream> combineStreams(VideoPlayerController videoController, MediaStream audioStream) async {
  final combinedStream = await createLocalMediaStream('combined_stream');
  return combinedStream;
  /*

  final videoElement = videoController.value.element;
  final videoStream = await videoElement.captureStream();
  final videoTrack = videoStream.getVideoTracks()[0];

  final audioTrack = audioStream.getAudioTracks()[0];

  combinedStream.addTrack(videoTrack);
  combinedStream.addTrack(audioTrack);

  return combinedStream;

   */
}

void publishStream(MediaStream stream) async {
  final configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  RTCPeerConnection peerConnection = await createPeerConnection(configuration);

  stream.getTracks().forEach((track) {
    peerConnection.addTrack(track, stream);
  });

  peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
    // Send the candidate to the remote peer
    // (e.g., using WebSocket)
  };

  RTCSessionDescription offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);

  // Send the offer to the remote peer
  // (e.g., using WebSocket)

  peerConnection.onTrack = (RTCTrackEvent event) {
    // Handle the incoming stream
    MediaStream remoteStream = event.streams[0];
    // For example, attach it to a video element
    // (using video_player or other method)
  };
}

// ignore_for_file: non_constant_identifier_names, unnecessary_this, curly_braces_in_flow_control_structures, unnecessary_new, avoid_print, prefer_const_constructors, constant_identifier_names, prefer_collection_literals, prefer_generic_function_type_aliases, prefer_final_fields, unnecessary_string_interpolations, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/websocket.dart'
    if (dart.library.js) '../utils/websocket_web.dart';

// AntHelper is an interface to the Flutter SDK of Ant Media Server
class AntHelper {
  MediaStream? _localStream;
  final List<RTCRtpSender> _senders = <RTCRtpSender>[];
  final List<MediaStream> _remoteStreams = [];
  final HelperStateCallback onStateChange;
  final StreamStateCallback onLocalStream;
  final StreamStateCallback onAddRemoteStream;
  final StreamStateCallback onRemoveRemoteStream;
  final DataChannelMessageCallback onDataChannelMessage;
  final DataChannelCallback onDataChannel;
  final ConferenceUpdateCallback onupdateConferencePerson;
  final Callbacks callbacks;
  final bool userScreen;
  final String _streamId;
  final String _roomId;
  final String _token;
  final String _host;
  final String streamName;

  // Max video and audio bitrate in kbps. Default: Unlimited
  int maxVideoBitrate = -1;
  int maxAudioBitrate = -1;

  late final Map<String, dynamic> _config;
  Timer? _ping;
  bool _mute = false;
  AntMediaType _type = AntMediaType.Default;
  bool DataChannelOnly = false;
  final List<Map<String, String>> iceServers;
  final List<Object> videoTrackAssignments = [];
  final Map<String, dynamic> allParticipants = {};

  // Constructor for AntHelper
  AntHelper(
    this._host,
    this._streamId,
    this.streamName,
    this._roomId,
    this._token,
    this.onStateChange,
    this.onAddRemoteStream,
    this.onDataChannel,
    this.onDataChannelMessage,
    this.onLocalStream,
    this.onRemoveRemoteStream,
    this.userScreen,
    this.onupdateConferencePerson,
    this.iceServers,
    this.callbacks,
  ) {
    final config = {
      "sdpSemantics": "unified-plan",
      'iceServers': iceServers,
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };
    if (_type == AntMediaType.DataChannelOnly) DataChannelOnly = true;
    _config = config;
  }

  final JsonEncoder _encoder = JsonEncoder();
  SimpleWebSocket? _socket;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  RTCDataChannel? _dataChannel;
  final List<RTCIceCandidate> _remoteCandidates = [];
  final Map<String, MediaStream> mediaStreamList = {};

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  final Map<String, dynamic> _dc_constraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  // Dispose local stream and close peer and websocket connections
  void close() {
    _localStream?.dispose();
    _localStream = null;

    _peerConnections.forEach((key, pc) {
      pc.close();
    });
    _socket?.close();
  }

  // Switch camera for the local stream
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      Helper.switchCamera(videoTrack);
    }
  }

  // Mute or unmute the local stream
  Future<void> muteMic(bool mute) async {
    if (_localStream != null) {
      final audioTrack = _localStream!
          .getAudioTracks()
          .firstWhere((track) => track.kind == 'audio');
      Helper.setMicrophoneMute(mute, audioTrack);
    }
  }

  // Toggle the camera on or off
  Future<void> toggleCam(bool state) async {
    if (_localStream != null) {
      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      videoTrack.enabled = state;
    }
  }

  // Stop publishing the stream
  void bye() {
    final request = {
      'command': 'stop',
      'streamId': _streamId,
    };
    _sendAntMedia(request);
  }

  // Stop a peer connection
  void disconnectPeer() {
    final request = {
      'streamId': _streamId,
      'command': 'leave',
    };
    _sendAntMedia(request);
  }

  // Receive sender tracks
  Future<RTCRtpSender?> getSender(String streamId, String type) async {
    final connection = _peerConnections[streamId];
    if (connection != null) {
      final senders = await connection.getSenders();
      for (final sender in senders) {
        if (sender.track!.kind == type) {
          return sender;
        }
      }
    }
    return null;
  }

  // Limit maximum bitrate for audio or video type
  Future<bool> setMaxBitrate(
      String streamId, String type, int maxBitrateKbps) async {
    final sender = await getSender(streamId, type);
    if (sender != null) {
      final parameters = sender.parameters;
      parameters.encodings?[0].maxBitrate = maxBitrateKbps * 1000;
      await sender.setParameters(parameters);
      return true;
    }
    return false;
  }

  void onMessage(Map<String, dynamic> mapData) async {
    final command = mapData['command'];
    print('current command is $command');

    switch (command) {
      case 'start':
        final id = mapData['streamId'];
        onStateChange(HelperState.CallStateNew);
        _peerConnections[id] =
            await _createPeerConnection(id, 'publish', userScreen);
        await _createDataChannel(_streamId, _peerConnections[_streamId]!);
        await _createOfferAntMedia(id, _peerConnections[id]!, 'publish');
        break;

      case 'takeConfiguration':
        final id = mapData['streamId'];
        final type = mapData['type'];
        var sdp = mapData['sdp'];
        final isTypeOffer = type == 'offer';
        sdp = sdp.replaceAll("a=extmap:13 urn:3gpp:video-orientation\r\n", "");
        final dataChannelMode = isTypeOffer ? "play" : "publish";

        print(
            "Flutter setRemoteDescription: $sdp for streamId: $id and type: $type");

        try {
          if (_peerConnections[id] == null) {
            _peerConnections[id] =
                await _createPeerConnection(id, dataChannelMode, userScreen);
            if (isTypeOffer) {
              await _createDataChannel(id, _peerConnections[id]!);
            }
          }

          await _peerConnections[id]!
              .setRemoteDescription(RTCSessionDescription(sdp, type));
          print("Remote description set successfully for streamId: $id");

          for (final candidate in _remoteCandidates) {
            await _peerConnections[id]!.addCandidate(candidate);
          }
          _remoteCandidates.clear();

          if (isTypeOffer) {
            print("Creating answer for streamId: $id");
            final answer =
                await _peerConnections[id]!.createAnswer(_dc_constraints);
            await _peerConnections[id]!.setLocalDescription(answer);

            final sdpWithStereo = answer.sdp!
                .replaceAll("useinbandfec=1", "useinbandfec=1; stereo=1");
            final request = {
              'command': 'takeConfiguration',
              'streamId': id,
              'type': answer.type,
              'sdp': sdpWithStereo,
            };
            _sendAntMedia(request);
            print("Answer created and sent for streamId: $id");
          }
        } catch (error) {
          print("Error setting remote description for streamId: $id: $error");
          if (error.toString().contains("InvalidAccessError") ||
              error.toString().contains("setRemoteDescription")) {
            print(
                "Error: Codec incompatibility or other issue setting remote description for streamId: $id");
          }
        }
        break;

      case 'stop':
        closePeerConnection(_streamId);
        break;

      case 'takeCandidate':
        final id = mapData['streamId'];
        final candidate = RTCIceCandidate(
            mapData['candidate'], mapData['id'], mapData['label']);
        if (_peerConnections[id] != null) {
          await _peerConnections[id]!.addCandidate(candidate);
        } else {
          _remoteCandidates.add(candidate);
        }
        break;

      case 'error':
        if (mapData['definition'] == 'no_stream_exist') {
          if (_type == AntMediaType.Conference) {
            Timer(Duration(seconds: 5), () {
              play(_roomId, "", _roomId, [], "", "", "");
            });
          } else if (_type == AntMediaType.Play) {
            Timer(Duration(seconds: 5), () {
              play(_streamId, "", _roomId, [], "", "", "");
            });
          }
        } else {
          print(mapData['definition']);
          onStateChange(HelperState.ConnectionError);
        }
        break;

      case 'notification':
        final decoder = JsonDecoder();
        if (mapData['definition'] == 'play_finished' &&
            _type == AntMediaType.Conference) {
          Timer(Duration(seconds: 5), () {
            play(_roomId, "", _roomId, [], "", "", "");
          });
        } else if (mapData['definition'] == 'publish_finished' ||
            mapData['definition'] == 'play_finished') {
          closePeerConnection(_streamId);
        } else if (mapData['definition'] == 'play_started' &&
            _type == AntMediaType.Conference) {
          _getBroadcastObject(_roomId);
        } else if (mapData['definition'] == 'broadcastObject' &&
            _type == AntMediaType.Conference) {
          final broadcastObject = decoder.convert(mapData['broadcast']);
          if (mapData['streamId'] == _roomId) {
            _handleMainTrackBroadcastObject(broadcastObject);
          } else {
            _handleSubTrackBroadcastObject(broadcastObject);
          }
          callbacks(command, mapData);
          print("$command${mapData['broadcast']}");
        } else if (mapData['definition'] == 'data_received') {
          final notificationEvent = decoder.convert(mapData['data']);
          _handleNotificationEvent(notificationEvent);
        }
        break;

      case 'pong':
        print(command);
        break;

      case 'trackList':
        print("$command $mapData");
        break;

      case 'connectWithNewId':
        if (_type == AntMediaType.Play ||
            _type == AntMediaType.Peer ||
            _type == AntMediaType.Conference) {
          join(_streamId);
        }
        break;

      case 'peerMessageCommand':
        print("$command $mapData");
        break;
    }
  }

  Future<void> connect(AntMediaType type) async {
    _type = type;
    final url = '$_host';
    _socket = SimpleWebSocket(url);

    if (_type == AntMediaType.DataChannelOnly) DataChannelOnly = true;

    print('connect to $url');

    _socket?.onOpen = () {
      print('onOpen');
      onStateChange(HelperState.ConnectionOpen);

      if (_type == AntMediaType.Publish ||
          _type == AntMediaType.DataChannelOnly) {
        publish(_streamId, _token, "", "", streamName, "", "");
      } else if (_type == AntMediaType.Conference) {
        publish(_streamId, _token, "", "", streamName, _roomId, "");
        play(_roomId, _token, _roomId, [], "", "", "");
      } else if (_type == AntMediaType.Play) {
        play(_streamId, _token, "", [], "", "", "");
      } else if (_type == AntMediaType.Peer) {
        join(_streamId);
      }
      _ping = Timer.periodic(Duration(seconds: 5), (timer) {
        final ping_msg = {'command': 'ping'};
        _sendAntMedia(ping_msg);
      });
    };

    _socket?.onMessage = (message) {
      print('Received data: $message');
      final decoder = JsonDecoder();
      onMessage(decoder.convert(message));
    };

    _socket?.onClose = (int code, String reason) {
      print('Closed by server [$code => $reason]!');
      _ping?.cancel();
      onStateChange(HelperState.ConnectionClosed);
    };

    await _socket?.connect();
  }

  // Create a local stream using camera or display
  Future<MediaStream> createStream(media, bool userScreen) async {
    final mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };

    final stream = userScreen
        ? await navigator.mediaDevices.getDisplayMedia(mediaConstraints)
        : await navigator.mediaDevices.getUserMedia(mediaConstraints);
    onLocalStream(stream);
    return stream;
  }

  // Set local stream
  void setStream(MediaStream? media) {
    _localStream = media;
  }

  Future<RTCPeerConnection> _createPeerConnection(
    String id,
    String media,
    bool userScreen,
  ) async {
    if (_type == AntMediaType.Publish ||
        _type == AntMediaType.Peer ||
        _type == AntMediaType.Conference ||
        _type == AntMediaType.Default) {
      if (media != 'data' && _localStream == null) {
        _localStream = await createStream(media, userScreen);
        _remoteStreams.add(_localStream!);
      }
    }

    final pc = await createPeerConnection(_config);

    if (_type == AntMediaType.Publish ||
        _type == AntMediaType.Peer ||
        _type == AntMediaType.Default ||
        (_type == AntMediaType.Conference &&
            _type != AntMediaType.DataChannelOnly)) {
      if (media != 'data' && _localStream != null) {
        for (final track in _localStream!.getTracks()) {
          final sender = await pc.addTrack(track, _localStream!);
          _senders.add(sender);
        }
      }
    }

    pc.onIceCandidate = (candidate) {
      final request = {
        'command': 'takeCandidate',
        'streamId': id,
        'label': candidate.sdpMLineIndex,
        'id': candidate.sdpMid,
        'candidate': candidate.candidate,
      };
      _sendAntMedia(request);
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected &&
          maxVideoBitrate != -1) {
        setMaxBitrate(id, "video", maxVideoBitrate);
        if (maxAudioBitrate != -1) {
          setMaxBitrate(id, "audio", maxAudioBitrate);
        }
      }
    };

    pc.onTrack = (event) {
      onupdateConferencePerson(event.streams[0]);
      onAddRemoteStream(event.streams[0]);
    };

    pc.onRemoveTrack = (stream, track) {
      onupdateConferencePerson(stream);
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(id, channel);
    };

    return pc;
  }

  void _addDataChannel(String id, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (data) {
      onDataChannelMessage(channel, data, true);
    };
    _dataChannel = channel;
    onDataChannel(channel);
  }

  Future<void> _createDataChannel(
    String id,
    RTCPeerConnection pc, {
    String label = 'fileTransfer',
  }) async {
    final dataChannelDict = RTCDataChannelInit();
    final channel = await pc.createDataChannel(label, dataChannelDict);
    _addDataChannel(id, channel);
  }

  Future<void> _createOfferAntMedia(
    String id,
    RTCPeerConnection pc,
    String media,
  ) async {
    try {
      final s = await pc
          .createOffer(DataChannelOnly ? _dc_constraints : _constraints);
      await pc.setLocalDescription(s);
      final request = {
        'command': 'takeConfiguration',
        'streamId': id,
        'type': s.type,
        'sdp': s.sdp,
      };
      _sendAntMedia(request);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _createAnswerAntMedia(
    String id,
    RTCPeerConnection pc,
    String media,
  ) async {
    try {
      final s = await pc
          .createAnswer(DataChannelOnly ? _dc_constraints : _constraints);
      await pc.setLocalDescription(s);
      final request = {
        'command': 'takeConfiguration',
        'streamId': id,
        'type': s.type,
        'sdp': s.sdp,
      };
      _sendAntMedia(request);
    } catch (e) {
      print(e.toString());
    }
  }

  // Send a request to the Ant Media Server using the websocket
  void _sendAntMedia(Map<String, dynamic> request) {
    _socket?.send(_encoder.convert(request));
  }

  // Close peer connection
  void closePeerConnection(String streamId) {
    print('bye: $streamId');
    if (_mute) muteMic(false);
    _localStream?.dispose();
    _localStream = null;
    final pc = _peerConnections.remove(streamId);
    pc?.close();
    _dataChannel?.close();
    _senders.clear();
    onStateChange(HelperState.CallStateBye);
  }

  // Register user push notification token to Ant Media Server
  void registerPushNotificationToken(
    String subscriberId,
    String authToken,
    String pushNotificationToken,
    String tokenType,
  ) {
    final request = {
      'command': 'registerPushNotificationToken',
      'subscriberId': subscriberId,
      'token': authToken,
      'pnsRegistrationToken': pushNotificationToken,
      'pnsType': tokenType,
    };
    _sendAntMedia(request);
  }

  // Send push notification to subscribers
  void sendPushNotification(
    String subscriberId,
    String authToken,
    Map pushNotificationContent,
    List subscriberIdsToNotify,
  ) {
    final request = {
      'command': 'sendPushNotification',
      'subscriberId': subscriberId,
      'token': authToken,
      'pushNotificationContent': pushNotificationContent.toString(),
      'subscriberIdsToNotify': subscriberIdsToNotify,
    };
    _sendAntMedia(request);
  }

  /// Called to start a new WebRTC stream. AMS responds with start message.
  /// Parameters:
  ///  @param {string} streamId : unique id for the stream
  ///  @param {string=} [token] : required if any stream security (token control) enabled.
  ///  @param {string=} [subscriberId] : required if TOTP enabled.
  ///  @param {string=} [subscriberCode] : required if TOTP enabled.
  ///  @param {string=} [streamName] : required if you want to set a name for the stream
  ///  @param {string=} [mainTrack] :  required if you want to start the stream as a subtrack for a main stream which has id of this parameter.
  ///  @param {string=} [metaData] : a free text information for the stream to AMS.
  void publish(
    String streamId,
    String token,
    String? subscriberId,
    String? subscriberCode,
    String? streamName,
    String? mainTrack,
    String? metaData,
  ) {
    final request = {
      'command': 'publish',
      'streamId': streamId,
      'token': token,
      'subscriberId': subscriberId,
      'subscriberCode': subscriberCode,
      'streamName': streamName,
      'mainTrack': mainTrack,
      'video': !DataChannelOnly,
      'audio': !DataChannelOnly,
      'metaData': metaData,
    };
    _sendAntMedia(request);
  }

  // Force stream into a specific quality
  void forceStreamQuality(String streamId, int resolution) {
    final request = {
      'command': 'forceStreamQuality',
      'streamId': streamId,
      'streamHeight': resolution,
    };
    print("Requesting new stream resolution $resolution");
    _sendAntMedia(request);
  }

  // Join into a conference room as player
  void join(String streamId) {
    final request = {
      'command': 'join',
      'streamId': streamId,
      'multiPeer': false,
      'mode': 'play or both',
    };
    _sendAntMedia(request);
  }

  void _handleMainTrackBroadcastObject(Map<String, dynamic> broadcast) {
    final participantIds = List<String>.from(broadcast['subTrackStreamIds']);

    // Find and remove not available tracks
    final currentTracks = allParticipants.keys;
    for (final trackId in currentTracks) {
      if (!participantIds.contains(trackId)) {
        print("Stream removed: $trackId");
        allParticipants.remove(trackId);
      }
    }

    // Request broadcast object for new tracks
    for (final pid in participantIds) {
      if (allParticipants[pid] == null) {
        _getBroadcastObject(pid);
      }
    }
  }

  void _handleSubTrackBroadcastObject(Map<String, dynamic> broadcast) {
    allParticipants[broadcast['streamId']] = broadcast;
    print("All participants: $allParticipants");
  }

  /// Called to start a playing session for a stream. AMS responds with start message.
  /// Parameters:
  ///  @param {string} streamId : unique id for the stream that you want to play
  ///  @param {string=} token : required if any stream security (token control) enabled.
  ///  @param {string=} roomId : required if this stream is belonging to a room participant
  ///  @param {Array.<MediaStreamTrack>=} enableTracks : required if the stream is a main stream of multitrack playing.
  ///  @param {string=} subscriberId : required if TOTP enabled.
  ///  @param {string=} subscriberCode : required if TOTP enabled.
  ///  @param {string=} metaData : a free text information for the stream to AMS.
  void play(
    String streamId,
    String? token,
    String? roomId,
    List<MediaStreamTrack> enableTracks,
    String? subscriberId,
    String? subscriberCode,
    String? metaData,
  ) {
    final request = {
      'command': 'play',
      'streamId': streamId,
      'token': token,
      'room': roomId,
      'trackList': enableTracks,
      'subscriberId': subscriberId,
      'subscriberCode': subscriberCode,
      'viewerInfo': metaData,
    };
    _sendAntMedia(request);
  }

  void _handleNotificationEvent(Map<String, dynamic> notificationEvent) {
    print("Notification event: ${notificationEvent.toString()}");
    final eventStreamId = notificationEvent['streamId'];
    final eventType = notificationEvent['eventType'];

    if (eventType == "CAM_TURNED_OFF" ||
        eventType == "CAM_TURNED_ON" ||
        eventType == "MIC_MUTED" ||
        eventType == "MIC_UNMUTED") {
      _getBroadcastObject(eventStreamId);
    } else if (eventType == "TRACK_LIST_UPDATED") {
      print("TRACK_LIST_UPDATED -> ${notificationEvent.toString()}");
      _getBroadcastObject(_roomId);
    }
  }

  // Send a text message using the WebRTC data channel
  Future<void> sendMessage(RTCDataChannelMessage message) async {
    if (_dataChannel != null) {
      await _dataChannel?.send(message);
      onDataChannelMessage(_dataChannel!, message, false);
    }
  }

  void _getBroadcastObject(String streamId) {
    final request = {
      'command': 'getBroadcastObject',
      'streamId': streamId,
    };
    _sendAntMedia(request);
  }

  void setMaxVideoBitrate(int videoBitrateInKbps) {
    maxVideoBitrate = videoBitrateInKbps;
  }

  void setMaxAudioBitrate(int audioBitrateInKbps) {
    maxAudioBitrate = audioBitrateInKbps;
  }
}

// ignore_for_file: non_constant_identifier_names, unnecessary_this, curly_braces_in_flow_control_structures, unnecessary_new, avoid_print, prefer_const_constructors, constant_identifier_names, prefer_collection_literals, prefer_generic_function_type_aliases, prefer_final_fields, unnecessary_string_interpolations, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/websocket.dart'
    if (dart.library.js) '../utils/websocket_web.dart';

// AntHelper is interface to the Flutter SDK of Ant Media Server
class AntHelper extends Object {
  MediaStream? _localStream;
  List<RTCRtpSender> _senders = <RTCRtpSender>[];
  List<MediaStream> _remoteStreams = [];
  HelperStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  StreamStateCallback onAddRemoteStream;
  StreamStateCallback onRemoveRemoteStream;
  DataChannelMessageCallback onDataChannelMessage;
  DataChannelCallback onDataChannel;
  ConferenceUpdateCallback onupdateConferencePerson;
  Callbacks callbacks;
  bool userScreen;
  String _streamId;
  String _roomId;
  String _token;
  String _host;
  //max video and audio bitrate in kbps. Default Unlimited
  var maxVideoBitrate = -1;
  var maxAudioBitrate = -1;
  Map<String, dynamic> _config = {};
  Timer? _ping;
  var _mute = false;
  AntMediaType _type = AntMediaType.Default;
  bool DataChannelOnly = false;
  List<Map<String, String>> iceServers;
  List<Object> videoTrackAssignments = [];
  Map<String, dynamic> allParticipants = {};

  // constructor for AntHelper
  AntHelper(
      this._host,
      this._streamId,
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
      this.callbacks) {
    final Map<String, dynamic> config = {
      "sdpSemantics": "unified-plan",
      'iceServers': iceServers,
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };
    if (this._type == AntMediaType.DataChannelOnly) DataChannelOnly = true;
    _config = config;
  }

  JsonEncoder _encoder = new JsonEncoder();
  SimpleWebSocket? _socket;

  var _peerConnections = new Map<String, RTCPeerConnection>();
  RTCDataChannel? _dataChannel;
  var _remoteCandidates = [];
  Map<String, MediaStream> mediaStreamList = {};

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

  // dispose local stream and close peer and websocket connections
  close() {
    if (_localStream != null) {
      _localStream?.dispose();
      _localStream = null;
    }

    _peerConnections.forEach((key, pc) {
      pc.close();
    });
    _socket?.close();
  }

  // switch camera for the local stream
  Future<void> switchCamera() async {
    if (_localStream != null) {
      //  if (_localStream == null) throw Exception('Stream is not initialized');

      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      Helper.switchCamera(videoTrack);
    }
  }

  // mute or unmute the local stream
  Future<void> muteMic(bool mute) async {
    if (_localStream != null) {
      final audioTrack = _localStream!
          .getAudioTracks()
          .firstWhere((track) => track.kind == 'audio');
      Helper.setMicrophoneMute(mute, audioTrack);
    }
  }

  // toggle the camera on or off
  Future<void> toggleCam(bool state) async {
    //true for on
    if (_localStream != null) {
      final videoTrack = _localStream!
          .getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      videoTrack.enabled = state;
    }
  }

  // stop publishing the stream
  void bye() {
    var request = new Map();
    request['command'] = 'stop';
    request['streamId'] = _streamId;

    _sendAntMedia(request);
  }

  // stop a peer connection
  void disconnectPeer() {
    var request = new Map();
    request['streamId'] = _streamId;
    request['command'] = 'leave';
    _sendAntMedia(request);
  }

  // receive sender tracks
  Future<RTCRtpSender?> getSender(streamId, type) async {
    if (_peerConnections.containsKey(streamId)) {
      var connection = _peerConnections[streamId];
      if (connection != null) {
        var senders = await connection.getSenders();
        for (var sender in senders) {
          if (sender.track!.kind == type) {
            return sender;
          }
        }
      }
    }
    return null;
  }

  // limit maximum bitrate for audio or video type
  setMaxBitrate(streamId, type, maxBitrateKbps) async {
    var sender = await getSender(streamId, type);
    if (sender != null) {
      var parameters = sender.parameters;
      parameters.encodings?[0].maxBitrate = maxBitrateKbps * 1000;
      return sender.setParameters(parameters);
    }
    return false;
  }

  void onMessage(message) async {
    Map<String, dynamic> mapData = message;
    var command = mapData['command'];
    print('current command is ' + command);

    switch (command) {
      case 'start':
        {
          var id = mapData['streamId'];

          this.onStateChange(HelperState.CallStateNew);

          _peerConnections[id] =
              await _createPeerConnection(id, 'publish', userScreen);

          await _createDataChannel(_streamId, _peerConnections[_streamId]!);
          await _createOfferAntMedia(id, _peerConnections[id]!, 'publish');
        }
        break;
      case 'takeConfiguration':
        {
          var id = mapData['streamId'];
          var type = mapData['type'];
          var sdp = mapData['sdp'];
          var isTypeOffer = (type == 'offer');

          // Remove unnecessary video orientation attribute if present
          sdp =
              sdp.replaceAll("a=extmap:13 urn:3gpp:video-orientation\r\n", "");

          var dataChannelMode = isTypeOffer
              ? "play"
              : "publish"; // Adjusted to manage the mode based on offer

          print(
              "Flutter setRemoteDescription: $sdp for streamId: $id and type: $type");

          // Asynchronous handling using Future.microtask to keep it thenable and catch errors
          Future.microtask(() async {
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

            // Process any queued remote candidates
            for (var candidate in _remoteCandidates) {
              await _peerConnections[id]!.addCandidate(candidate);
            }
            _remoteCandidates.clear();

            if (isTypeOffer) {
              print("Creating answer for streamId: $id");
              var answer = await _peerConnections[id]!
                  .createAnswer(_dc_constraints); // Use appropriate constraints
              await _peerConnections[id]!.setLocalDescription(answer);

              var sdpWithStereo = answer.sdp!
                  .replaceAll("useinbandfec=1", "useinbandfec=1; stereo=1");

              // Send the answer SDP back to the server
              var request = {
                'command': 'takeConfiguration',
                'streamId': id,
                'type': answer.type,
                'sdp': sdpWithStereo,
              };
              _sendAntMedia(request);
              print("Answer created and sent for streamId: $id");
            }
          }).catchError((error) {
            print("Error setting remote description for streamId: $id: $error");
            // Handle specific errors or general failure
            if (error.toString().contains("InvalidAccessError") ||
                error.toString().contains("setRemoteDescription")) {
              print(
                  "Error: Codec incompatibility or other issue setting remote description for streamId: $id");
            }
          });
        }
        break;
      case 'stop':
        {
          closePeerConnection(_streamId);
        }
        break;

      case 'takeCandidate':
        {
          var id = mapData['streamId'];
          RTCIceCandidate candidate = new RTCIceCandidate(
              mapData['candidate'], mapData['id'], mapData['label']);
          if (_peerConnections[id] != null) {
            await _peerConnections[id]!.addCandidate(candidate);
          } else {
            _remoteCandidates.add(candidate);
          }
        }
        break;

      case 'error':
        {
          if (mapData['definition'] == 'no_stream_exist') {
            if (_type == AntMediaType.Conference) {
              Timer(Duration(seconds: 5), () {
              play(
                  _roomId,
                  "",
                  _roomId,
                  [],
                  "",
                  "",
                  "");
            });
            } else if (_type == AntMediaType.Play) {
        Timer(Duration(seconds: 5), () {
              play(
                  _streamId,
                  "",
                  _roomId,
                  [],
                  "",
                  "",
                  "");
            }
            );
            }
            return;
          } else {
            print(mapData['definition']);
            onStateChange(HelperState.ConnectionError);
          }
        }
        break;

      case 'notification':
        {
          JsonDecoder decoder = new JsonDecoder();

          if (mapData['definition'] == 'play_finished' &&
              _type == AntMediaType.Conference) {
            Timer(Duration(seconds: 5), () {
              play(_roomId, "", _roomId, [], "", "", "");
            });
            return;
          }

          if (mapData['definition'] == 'publish_finished' ||
              mapData['definition'] == 'play_finished') {
            closePeerConnection(_streamId);
          }

          if ((mapData['definition'] == 'play_started') &&
              (_type == AntMediaType.Conference)) {
            _getBroadcastObject(_roomId);
          }

          if ((mapData['definition'] == 'broadcastObject') &&
              (_type == AntMediaType.Conference)) {
            var broadcastObject = decoder.convert(mapData['broadcast']);

            if (mapData['streamId'] == _roomId) {
              _handleMainTrackBroadcastObject(broadcastObject);
            } else {
              _handleSubTrackBroadcastObject(broadcastObject);
            }

            this.callbacks(command, mapData);
            print(command + '' + mapData['broadcast']);
          }

          if (mapData['definition'] == 'data_received') {
            var notificationEvent = decoder.convert(mapData['data']);
            _handleNotificationEvent(notificationEvent);
          }
          break;
        }
      case 'pong':
        {
          print(command);
        }
        break;
      case 'trackList':
        {
          print(command + ' ' + mapData);
        }
        break;
      case 'connectWithNewId':
        {
          if (_type == AntMediaType.Play ||
              _type == AntMediaType.Peer ||
              _type == AntMediaType.Conference) {
            join(_streamId);
          }
        }
        break;
      case 'peerMessageCommand':
        {
          print(command + ' ' + mapData);
        }
        break;
    }
  }

  connect(AntMediaType type) async {
    // _initializeData();
    _type = type;
    var url = '$_host';
    _socket = SimpleWebSocket(url);

    if (this._type == AntMediaType.DataChannelOnly) DataChannelOnly = true;

    print('connect to $url');

    _socket?.onOpen = () {
      print('onOpen');
      this.onStateChange(HelperState.ConnectionOpen);

      if (_type == AntMediaType.Publish ||
          _type == AntMediaType.DataChannelOnly) {
        publish(_streamId, _token, "", "", _streamId, "", "");
      }
      if (_type == AntMediaType.Conference) {
        publish(_streamId, _token, "", "", _streamId, _roomId, "");
        play(_roomId, _token, _roomId, [], "", "", "");
      }
      if (_type == AntMediaType.Play) {
        play(_streamId, _token, "", [], "", "", "");
      }
      if (_type == AntMediaType.Peer) {
        join(_streamId);
      }
      _ping = Timer.periodic(Duration(seconds: 5), (Timer timer) {
        var ping_msg = new Map();
        ping_msg['command'] = 'ping';
        _sendAntMedia(ping_msg);
      });
    };

    _socket?.onMessage = (message) {
      print('Received data: ' + message);
      JsonDecoder decoder = new JsonDecoder();
      this.onMessage(decoder.convert(message));
    };

    _socket?.onClose = (int code, String reason) {
      print('Closed by server [$code => $reason]!');
      _ping?.cancel();
      this.onStateChange(HelperState.ConnectionClosed);
    };

    await _socket?.connect();
  }

  // create a local stream using camera or display
  Future<MediaStream> createStream(media, userScreen) async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };

    MediaStream stream = userScreen
        ? await navigator.mediaDevices.getDisplayMedia(mediaConstraints)
        : await navigator.mediaDevices.getUserMedia(mediaConstraints);
    this.onLocalStream(stream);
    return stream;
  }

  // set local stream
  setStream(MediaStream? media) {
    _localStream = media;
  }

  _createPeerConnection(id, media, user_Screen) async {
    if (_type == AntMediaType.Publish ||
        _type == AntMediaType.Peer ||
        _type == AntMediaType.Conference ||
        _type == AntMediaType.Default) {
      if (media != 'data' && _localStream == null)
        _localStream = await createStream(media, user_Screen);
      _remoteStreams.add(_localStream!);
    }

    RTCPeerConnection pc = await createPeerConnection(_config);

    if (_type == AntMediaType.Publish ||
        _type == AntMediaType.Peer ||
        _type == AntMediaType.Default ||
        _type == AntMediaType.Conference &&
            _type != AntMediaType.DataChannelOnly) {
      if (media != 'data' && _localStream != null) {
        _localStream!.getTracks().forEach((track) async {
          _senders.add(await pc.addTrack(track, _localStream!));
        });
      } //pc.addStream(_localStream!);
    }

    pc.onIceCandidate = (candidate) {
      var request = new Map();
      request['command'] = 'takeCandidate';
      request['streamId'] = id;
      request['label'] = candidate.sdpMLineIndex;
      request['id'] = candidate.sdpMid;
      request['candidate'] = candidate.candidate;
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

    pc.onTrack = (event) async {
      this.onupdateConferencePerson(event.streams[0]);
      this.onAddRemoteStream(event.streams[0]);
    };

    pc.onRemoveTrack = (stream, track) {
      this.onupdateConferencePerson(stream);
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(id, channel);
    };

    if (_type == AntMediaType.Publish ||
        _type == AntMediaType.Peer ||
        _type == AntMediaType.Conference &&
            _type != AntMediaType.DataChannelOnly) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    return pc;
  }

  _addDataChannel(id, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      this.onDataChannelMessage(channel, data, true);
    };
    _dataChannel = channel;

    this.onDataChannel(channel);
  }

  _createDataChannel(id, RTCPeerConnection pc, {label = 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = new RTCDataChannelInit();
    RTCDataChannel channel = await pc.createDataChannel(label, dataChannelDict);
    _addDataChannel(id, channel);
  }

  _createOfferAntMedia(String id, RTCPeerConnection pc, String media) async {
    try {
      RTCSessionDescription s = await pc
          .createOffer(DataChannelOnly ? _dc_constraints : _constraints);
      pc.setLocalDescription(s);
      var request = new Map();
      request['command'] = 'takeConfiguration';
      request['streamId'] = id;
      request['type'] = s.type;
      request['sdp'] = s.sdp;
      _sendAntMedia(request);
    } catch (e) {
      print(e.toString());
    }
  }

  _createAnswerAntMedia(String id, RTCPeerConnection pc, media) async {
    try {
      RTCSessionDescription s = await pc
          .createAnswer(DataChannelOnly ? _dc_constraints : _constraints);
      pc.setLocalDescription(s);

      var request = new Map();
      request['command'] = 'takeConfiguration';
      request['streamId'] = id;
      request['type'] = s.type;
      request['sdp'] = s.sdp;
      _sendAntMedia(request);
    } catch (e) {
      print(e.toString());
    }
  }

  // send a request to the Ant Media Server using the websocket
  _sendAntMedia(request) {
    _socket?.send(_encoder.convert(request));
  }

  // close peer connection
  closePeerConnection(streamId) {
    var id = streamId;
    print('bye: ' + id);
    if (_mute) muteMic(false);
    if (_localStream != null) {
      _localStream?.dispose();
      _localStream = null;
    }
    var pc = _peerConnections[id];
    if (pc != null) {
      pc.close();
      _peerConnections.remove(id);
    }
    var dc = _dataChannel;
    if (dc != null) {
      dc.close();
    }
    _senders.clear();
    this.onStateChange(HelperState.CallStateBye);
  }

  /// Called to start a new WebRTC stream. AMS responds with start message.
  /// Parameters:
  ///  @param {string} streamId : unique id for the stream
  ///  @param {string=} [token] : required if any stream security (token control) enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Stream-Security-Documentation
  ///  @param {string=} [subscriberId] : required if TOTP enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Time-based-One-Time-Password-(TOTP)
  ///  @param {string=} [subscriberCode] : required if TOTP enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Time-based-One-Time-Password-(TOTP)
  ///  @param {string=} [streamName] : required if you want to set a name for the stream
  ///  @param {string=} [mainTrack] :  required if you want to start the stream as a subtrack for a main stream which has id of this parameter.
  ///                Check:https://antmedia.io/antmediaserver-webrtc-multitrack-playing-feature/
  ///                !!! for multitrack conference set this value with roomName
  ///  @param {string=} [metaData] : a free text information for the stream to AMS. It is provided to Rest methods by the AMS
  publish(streamId, token, subscriberId, subscriberCode, streamName, mainTrack,
      metaData) {
    var request = new Map();
    request['command'] = 'publish';
    request['streamId'] = streamId;
    request['token'] = token;
    request['subscriberId'] = subscriberId;
    request['subscriberCode'] = subscriberCode;
    request['streamName'] = streamName;
    request['mainTrack'] = mainTrack;
    request['video'] = !DataChannelOnly;
    request['audio'] = !DataChannelOnly;
    request['metaData'] = metaData;
    _sendAntMedia(request);
  }

  // force stream into a specific quality
  forceStreamQuality(streamId, resolution) {
    var request = new Map();
    request['command'] = 'forceStreamQuality';
    request['streamId'] = streamId;
    request['streamHeight'] = resolution;
    print("requesting new stream resolution $resolution");
    _sendAntMedia(request);
  }

  // join into a conference room as player
  join(streamId) {
    var request = new Map();
    request['command'] = 'join';
    request['streamId'] = streamId;
    request['multiPeer'] = false;
    request['mode'] = 'play or both';
    _sendAntMedia(request);
  }

  _handleMainTrackBroadcastObject(broadcast) {
    var participantIds = broadcast['subTrackStreamIds'];

    //find and remove not available tracks
    var currentTracks = allParticipants.keys;
    for (var trackId in currentTracks) {
      if (!participantIds.contains(trackId)) {
        print("stream removed:$trackId");
        allParticipants.remove(trackId);
      }
    }

    //request broadcast object for new tracks
    participantIds.forEach((pid) {
      if (allParticipants[pid] == null) {
        _getBroadcastObject(pid);
      }
    });
  }

  _handleSubTrackBroadcastObject(broadcast) {
    allParticipants[broadcast['streamId']] = broadcast;

    print("allParticipants: $allParticipants");
  }

  /// Called to start a playing session for a stream. AMS responds with start message.
  /// Parameters:
  ///  @param {string} streamId :(string) unique id for the stream that you want to play
  ///  @param {string=} token :(string) required if any stream security (token control) enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Stream-Security-Documentation
  ///  @param {string=} roomId :(string) required if this stream is belonging to a room participant
  ///  @param {Array.<MediaStreamTrack>=} enableTracks :(array) required if the stream is a main stream of multitrack playing. You can pass the the subtrack id list that you want to play.
  ///                    you can also provide a track id that you don't want to play by adding ! before the id.
  ///  @param {string=} subscriberId :(string) required if TOTP enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Time-based-One-Time-Password-(TOTP)
  ///  @param {string=} subscriberCode :(string) required if TOTP enabled. Check https://github.com/ant-media/Ant-Media-Server/wiki/Time-based-One-Time-Password-(TOTP)
  ///  @param {string=} metaData :(string, json) a free text information for the stream to AMS. It is provided to Rest methods by the AMS
  play(streamId, token, roomId, enableTracks, subscriberId, subscriberCode,
      metaData) {
    var request = new Map();
    request['command'] = 'play';
    request['streamId'] = streamId;
    request['token'] = token;
    request['room'] = roomId;
    request['trackList'] = enableTracks;
    request['subscriberId'] = subscriberId;
    request['subscriberCode'] = subscriberCode;
    request['viewerInfo'] = metaData;
    _sendAntMedia(request);
  }

  _handleNotificationEvent(notificationEvent) {
    print("notificationEvent: ${notificationEvent.toString()}");
    var eventStreamId = notificationEvent['streamId'];
    var eventType = notificationEvent['eventType'];

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

  // send a text message using the WebRTC data channel
  Future<void> sendMessage(RTCDataChannelMessage message) async {
    if (_dataChannel != null) {
      await _dataChannel?.send(message);
      onDataChannelMessage(_dataChannel!, message, false);
    }
  }

  _getBroadcastObject(
    streamId,
  ) {
    var request = new Map();
    request['command'] = 'getBroadcastObject';
    request['streamId'] = streamId;
    _sendAntMedia(request);
  }

  setMaxVideoBitrate(videoBitrateInKbps) {
    this.maxVideoBitrate = videoBitrateInKbps;
  }

  setMaxAudioBitrate(audioBitrateInKbps) {
    this.maxAudioBitrate = audioBitrateInKbps;
  }

  /// Register user push notification token to Ant Media Server according to subscriberId and authToken
  registerPushNotificationToken(String subscriberId, String authToken,
      String pushNotificationToken, String tokenType) {
    var request = new Map();
    request['command'] = 'registerPushNotificationToken';
    request['subscriberId'] = subscriberId;
    request['token'] = authToken;
    request['pnsRegistrationToken'] = pushNotificationToken;
    request['pnsType'] = tokenType;
    _sendAntMedia(request);
  }

  /// Send push notification to subscribers
  void sendPushNotification(String subscriberId, String authToken,
      Map pushNotificationContent, List subscriberIdsToNotify) {
    var request = new Map();
    request['command'] = 'sendPushNotification';
    request['subscriberId'] = subscriberId;
    request['token'] = authToken;
    request['pushNotificationContent'] = pushNotificationContent.toString();
    request['subscriberIdsToNotify'] = subscriberIdsToNotify;
    _sendAntMedia(request);
  }
}

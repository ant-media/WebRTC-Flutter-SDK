import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/webrtc.dart';

import 'random_string.dart';


import '../utils/websocket.dart'
    if (dart.library.js) '../utils/websocket_web.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

/*
 * callbacks for Signaling API.
 */
typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);
typedef void DataChannelMessageCallback(
    RTCDataChannel dc, RTCDataChannelMessage data);
typedef void DataChannelCallback(RTCDataChannel dc);

class Signaling {
  JsonEncoder _encoder = new JsonEncoder();
  JsonDecoder _decoder = new JsonDecoder();
  String _selfId = randomNumeric(6);
  SimpleWebSocket _socket;
  var _sessionId;
  var _host;
  //var _port = '/WebRTCAppEE/websocket';
  var _peerConnections = new Map<String, RTCPeerConnection>();
  var _dataChannels = new Map<String, RTCDataChannel>();
  var _remoteCandidates = [];
  var _turnCredential;
  var _streamId;
  var _type;
  var _mute=false;

  MediaStream _localStream;
  List<MediaStream> _remoteStreams;
  SignalingStateCallback onStateChange;
  StreamStateCallback onLocalStream;
  StreamStateCallback onAddRemoteStream;
  StreamStateCallback onRemoveRemoteStream;
  OtherEventCallback onPeersUpdate;
  DataChannelMessageCallback onDataChannelMessage;
  DataChannelCallback onDataChannel;

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      /*
       * turn server configuration example.
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
       */
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

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

  Signaling(this._host, this._type, this._streamId);

  close() {
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }

    _peerConnections.forEach((key, pc) {
      pc.close();
    });
    if (_socket != null) _socket.close();
  }

  void switchCamera() {
    if (_localStream != null) {
      _localStream.getVideoTracks()[0].switchCamera();
    }
  }
  void muteMic(){
    if(_localStream!=null)
      if(_mute==false) {
        _localStream.getAudioTracks()[0].setMicrophoneMute(true);
        _mute=true;
      }
      else{
        _localStream.getAudioTracks()[0].setMicrophoneMute(false);
        _mute=false;
      }
  }

  void invite(String peer_id, String media, use_screen) {
    this._sessionId = this._selfId + '-' + peer_id;

    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateNew);
    }

    _createPeerConnection(peer_id, media, use_screen).then((pc) {
      _peerConnections[peer_id] = pc;
      if (media == 'data') {
        _createDataChannel(peer_id, pc);
      }
      _createOfferAntMedia(peer_id, pc, media);
    });
  }

  void bye() {
    var request = new Map();
    request['command'] = 'stop';
    request['streamId'] = _streamId;
    _sendAntMedia(request);
  }

  void onMessage(message) async {
    Map<String, dynamic> mapData = message;
    var command = mapData['command'];
    //var candidateMap=mapData["candidate"];
    print('current command is ' + command);

    switch (command) {
      case 'start':
        {
          var id = mapData['streamId'];
          if (this.onStateChange != null) {
            this.onStateChange(SignalingState
                .CallStateNew);
          }

          _peerConnections[id] =
              await _createPeerConnection(id, 'publish', false);
          //_peerConnections[id] = pc;
          await _createOfferAntMedia(id, _peerConnections[id], 'publish');
        }
        break;
      case 'takeConfiguration':
        {
          var id = mapData['streamId'];
          var type = mapData['type'];
          var sdp = mapData['sdp'];
          var isTypeOffer = (type == 'offer');
          var dataChannelMode = 'publish';
          if (isTypeOffer) dataChannelMode = 'play';
          if (isTypeOffer) {
            if (this.onStateChange != null) {
              this.onStateChange(SignalingState.CallStateNew);
            }
            _peerConnections[id] =
                await _createPeerConnection(id, 'play', false);
          }
          await _peerConnections[id]
              .setRemoteDescription(new RTCSessionDescription(sdp, type));
          for(int i=0;i<_remoteCandidates.length;i++){
            await _peerConnections[id].addCandidate(_remoteCandidates[i]);
          }
          _remoteCandidates=[];
          if (isTypeOffer)
            await _createAnswerAntMedia(id, _peerConnections[id], 'play');
        }
        break;
      case 'stop':
        {
          _closePeerConnection(_streamId);
        }
        break;

      case 'takeCandidate':
        {
          var id = mapData['streamId'];
          //var candidateMap = mapData['candidate'];
          //var dataChannelMode = 'peer';
          RTCIceCandidate candidate = new RTCIceCandidate(
              mapData['candidate'], mapData['id'], mapData['label']);
          if (_peerConnections[id] != null) {
            await _peerConnections[id].addCandidate(candidate);
          } else {
            _remoteCandidates.add(candidate);
          }
        }
        break;

      case 'error':
        {
          print(mapData['definition']);
        }
        break;

      case 'notification':
        {
          if (mapData['definition'] == 'play_finished' ||
              mapData['definition'] == 'publish_finished') {
            _closePeerConnection(_streamId);
          }
        }
        break;
      case 'streamInformation':
        {
          print(command + '' + mapData);
        }
        break;
      case 'roomInformation':
        {
          print(command + ' ' + mapData);
        }
        break;
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
          join(_streamId);
        }
        break;
      case 'peerMessageCommand':
        {
          print(command + ' ' + mapData);
        }
        break;
    }
  }

  void connect() async {
    //var url = '$_host$_port';
    var url = '$_host';
    _socket = SimpleWebSocket(url);

    print('connect to $url');

    /*if (_turnCredential == null) {
      try {
        _turnCredential = await getTurnCredential(_host, _port);
        /*{
            "username": "1584195784:mbzrxpgjys",
            "password": "isyl6FF6nqMTB9/ig5MrMRUXqZg",
            "ttl": 86400,
            "uris": ["turn:127.0.0.1:19302?transport=udp"]
          }
        */
        _iceServers = {
          'iceServers': [
            {
              'url': _turnCredential['uris'][0],
              'username': _turnCredential['username'],
              'credential': _turnCredential['password']
            },
          ]
        };
      } catch (e) {}
    }*/

    _socket.onOpen = () {
      print('onOpen');
      print(_type);
      this?.onStateChange(SignalingState.ConnectionOpen);
      if (_type == "play")
        _startPlayingAntMedia(_streamId);
      else if (_type == "publish") _startStreamingAntMedia(_streamId);
    };

    _socket.onMessage = (message) {
      print('Received data: ' + message);
      JsonDecoder decoder = new JsonDecoder();
      this.onMessage(decoder.convert(message));
    };

    _socket.onClose = (int code, String reason) {
      print('Closed by server [$code => $reason]!');
      if (this.onStateChange != null) {
        this.onStateChange(SignalingState.ConnectionClosed);
      }
    };

    await _socket.connect();
  }

  Future<MediaStream> createStream(media, user_screen) async {
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

    MediaStream stream = user_screen
        ? await navigator.getDisplayMedia(mediaConstraints)
        : await navigator.getUserMedia(mediaConstraints);
    if (this.onLocalStream != null) {
      this.onLocalStream(stream);
    }
    return stream;
  }

  _createPeerConnection(id, media, user_screen) async {
    if(_type!='play')
      if (media != 'data') _localStream = await createStream(media, user_screen);
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);
    if (media != 'data') pc.addStream(_localStream);
    pc.onIceCandidate = (candidate) {
      var request = new Map();
      request['command'] = 'takeCandidate';
      request['streamId'] = id;
      request['label'] = candidate.sdpMlineIndex;
      request['id'] = candidate.sdpMid;
      request['candidate'] = candidate.candidate;
      _sendAntMedia(request);
    };


    pc.onIceConnectionState = (state) {};

    pc.onAddStream = (stream) {
      if (this.onAddRemoteStream != null) this.onAddRemoteStream(stream);
      //_remoteStreams.add(stream);
    };

    pc.onRemoveStream = (stream) {
      if (this.onRemoveRemoteStream != null) this.onRemoveRemoteStream(stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(id, channel);
    };

    return pc;
  }

  _addDataChannel(id, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      if (this.onDataChannelMessage != null)
        this.onDataChannelMessage(channel, data);
    };
    _dataChannels[id] = channel;

    if (this.onDataChannel != null) this.onDataChannel(channel);
  }

  _createDataChannel(id, RTCPeerConnection pc, {label: 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = new RTCDataChannelInit();
    RTCDataChannel channel = await pc.createDataChannel(label, dataChannelDict);
    _addDataChannel(id, channel);
  }

  _createOfferAntMedia(String id, RTCPeerConnection pc, String media) async {
    try {
      RTCSessionDescription s = await pc
          .createOffer(media == 'data' ? _dc_constraints : _constraints);
      pc.setLocalDescription(s);
      print('s.type is:  ' + s.type);
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
          .createAnswer(media == 'data' ? _dc_constraints : _constraints);
      pc.setLocalDescription(s);
      print('s.type is:  ' + s.type);
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

  _sendAntMedia(request) {
    _socket.send(_encoder.convert(request));
  }

  _closePeerConnection(streamId) {
    var id = streamId;
    print('bye: ' + id);
    if(_mute)
      muteMic();
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null;
    }
    var pc = _peerConnections[id];
    if (pc != null) {
      pc.close();
      _peerConnections.remove(id);
    }
    var dc = _dataChannels[id];
    if (dc != null) {
      dc.close();
      _dataChannels.remove(id);
    }
    this._sessionId = null;
    if (this.onStateChange != null) {
      this.onStateChange(SignalingState.CallStateBye);
    }
  }

  join(streamId) {
    var request = new Map();
    request['command'] = 'join';
    request['streamId'] = streamId;
    request['multiPeer'] = false;
    request['mode'] = 'play';
    _sendAntMedia(request);
  }

  _startStreamingAntMedia(streamId) {
    var request = new Map();
    request['command'] = 'publish';
    request['streamId'] = streamId;
    request['token'] = '';
    request['video'] = true;
    request['audio'] = true;
    _sendAntMedia(request);
  }

  _startPlayingAntMedia(streamId) {
    var request = new Map();
    request['command'] = 'play';
    request['streamId'] = streamId;
    request['token'] = '';
    _sendAntMedia(request);
  }
}

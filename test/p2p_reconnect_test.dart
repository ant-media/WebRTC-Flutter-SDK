// Reproduces the "NoSpaceForNewPeer after network reconnect" report for 1:1
// peer calls against test.antmedia.io (needs internet).
//
// A local TCP proxy sits between the old client and the server so we can
// simulate the phone losing its network: traffic silently stops and the
// server keeps the dead session in the room. Later the proxy closes the
// upstream connection, which stands in for the server finally noticing the
// dead socket. AntHelper must keep retrying until then.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:ant_media_flutter/src/helpers/helper.dart';
import 'package:flutter_test/flutter_test.dart';

const serverHost = 'test.antmedia.io';
const serverPort = 5443;
const serverUrl = 'wss://$serverHost:$serverPort/WebRTCAppEE/websocket';

class DropProxy {
  final ServerSocket _server;
  final _upstreams = <Socket>[];
  bool _silent = false;

  DropProxy._(this._server, String host, int port) {
    _server.listen((client) async {
      final upstream = await Socket.connect(host, port);
      _upstreams.add(upstream);
      client.listen((d) => _silent ? null : upstream.add(d),
          onDone: () => _silent ? null : upstream.destroy());
      upstream.listen((d) => _silent ? null : client.add(d),
          onDone: () => _silent ? null : client.destroy());
    });
  }

  static Future<DropProxy> start(String host, int port) async => DropProxy._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0), host, port);

  int get port => _server.port;

  // Network gone: packets just stop, nobody gets a FIN.
  void goSilent() => _silent = true;

  // Server finally notices the dead socket and closes it.
  void serverDropsDeadSockets() => _upstreams.forEach((u) => u.destroy());

  Future<void> close() => _server.close();
}

Stream<Map<String, dynamic>> messages(WebSocket ws) => ws
    .map((m) => jsonDecode(m as String) as Map<String, dynamic>)
    .asBroadcastStream();

// Same request AntHelper.join() sends.
void join(WebSocket ws, String streamId) => ws.add(jsonEncode({
      'command': 'join',
      'streamId': streamId,
      'multiPeer': false,
      'mode': 'play or both',
    }));

Future<Map<String, dynamic>> joinResult(Stream<Map<String, dynamic>> msgs) =>
    msgs
        .firstWhere((m) =>
            m['command'] == 'error' || m['definition'] == 'joined')
        .timeout(const Duration(seconds: 10));

void main() {
  test('peer rejoins a 1:1 call once the server drops its dead session',
      () async {
    final streamId = 'flutter-p2p-repro-${DateTime.now().millisecondsSinceEpoch}';
    final proxy = await DropProxy.start(serverHost, serverPort);
    final viaProxy = HttpClient()
      ..connectionFactory = (uri, _, __) async => ConnectionTask.fromSocket(
          Socket.connect('127.0.0.1', proxy.port)
              .then((s) => SecureSocket.secure(s, host: uri.host)),
          () {});

    // Flutter user joins through the proxy, operator joins directly.
    final flutterUser = await WebSocket.connect(serverUrl, customClient: viaProxy);
    final flutterMsgs = messages(flutterUser);
    join(flutterUser, streamId);
    expect((await joinResult(flutterMsgs))['definition'], 'joined');

    final operator = await WebSocket.connect(serverUrl);
    final operatorMsgs = messages(operator);
    join(operator, streamId);
    expect((await joinResult(operatorMsgs))['definition'], 'joined');

    // Wi-Fi and mobile data off.
    proxy.goSilent();
    await Future.delayed(const Duration(seconds: 3));

    // Network back: the app reconnects with the SDK, same stream id.
    final serverReplies = <String>[];
    final joined = Completer<void>();
    final helper = AntHelper(
      true,
      serverUrl,
      streamId,
      '',
      '',
      (_) {},
      (_) {},
      (_) {},
      (_, __, ___) {},
      (_) {},
      (_) {},
      false,
      (_) {},
      [],
      (command, mapData) {
        final definition = mapData['definition'];
        if (definition != null) serverReplies.add('$definition');
        // The server notices the dead socket only after the first rejoin
        // attempt has already been rejected.
        if (definition == 'NoSpaceForNewPeer' && serverReplies.length == 1) {
          Timer(const Duration(seconds: 2), proxy.serverDropsDeadSockets);
        }
        if (definition == 'joined' && !joined.isCompleted) joined.complete();
      },
      autoConfigureAudio: false,
    );
    await helper.connect(AntMediaType.Peer);

    await expectLater(
        joined.future.timeout(
            AntHelper.peerRejoinDelay + const Duration(seconds: 10)),
        completes,
        reason: 'never rejoined, server replies: $serverReplies');
    expect(serverReplies.first, 'NoSpaceForNewPeer',
        reason: 'first attempt should hit the stale session');

    helper.close();
    await operator.close();
    await proxy.close();
  }, timeout: const Timeout(Duration(minutes: 1)));
}

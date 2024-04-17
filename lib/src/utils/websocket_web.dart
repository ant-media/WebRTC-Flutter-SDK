// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:flutter/foundation.dart';

class SimpleWebSocket {
  String _url;
  WebSocket? _socket;
  Function()? onOpen;
  Function(dynamic msg)? onMessage;
  Function(int code, String reason)? onClose;

  SimpleWebSocket(this._url) {
    _url = _url.replaceAll('https:', 'wss:');
  }

  connect() async {
    try {
      _socket = WebSocket(_url);
      _socket!.onOpen.listen((e) {
        onOpen?.call();
      });

      _socket!.onMessage.listen((e) {
        onMessage?.call(e.data);
      });

      _socket!.onClose.listen((e) {
        onClose?.call(e.code!, e.reason!);
      });
    } catch (e) {
      onClose?.call(500, e.toString());
    }
  }

  send(data) {
    if (_socket != null && _socket!.readyState == WebSocket.OPEN) {
      _socket!.send(data);
      if (kDebugMode) {
        print('send: $data');
      }
    } else {
      if (kDebugMode) {
        print('WebSocket not connected, message $data not sent');
      }
    }
  }

  close() {
    if (_socket != null) {
      _socket!.close();
    }
  }
}

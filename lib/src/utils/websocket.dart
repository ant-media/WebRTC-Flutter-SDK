import 'dart:io';

typedef OnMessageCallback = void Function(dynamic msg);
typedef OnCloseCallback = void Function(int code, String reason);
typedef OnOpenCallback = void Function();

class SimpleWebSocket {
  String _url;
  WebSocket? _socket;
  OnOpenCallback? onOpen;
  OnMessageCallback? onMessage;
  OnCloseCallback? onClose;

  SimpleWebSocket(this._url);

  connect() async {
    try {
      _socket = await WebSocket.connect(_url);
      //_socket = await _connectForSelfSignedCert(_url);

      if (this.onOpen != null) {
        this.onOpen!();
      }

      _socket!.listen((data) {
        if (this.onMessage != null) {
          this.onMessage!(data);
        }
      }, onDone: () {
        if (this.onClose != null) {
          this.onClose!(_socket!.closeCode!, _socket!.closeReason!);
        }
      });
    } catch (e) {
      if (this.onClose != null) {
        this.onClose!(500, e.toString());
      }
    }
  }

  void send(data) {
    if (_socket != null) {
      _socket!.add(data);
      print('send: $data');
    }
  }

  close() {
    if (_socket != null) _socket!.close();
  }
}

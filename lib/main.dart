import 'dart:core';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';


import 'src/call_sample/call_sample.dart';

import 'src/route_item.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MyAppState extends State<MyApp> {
  List<RouteItem> items;
  String _server = '';
  SharedPreferences _prefs;
  String _streamId = '';
  final navigatorKey = GlobalKey<NavigatorState>();
  bool _play = false;

  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
          appBar: AppBar(
            title: Text('Ant Media Server Play/Publish'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  _showServerAddressDialog(context);
                },
                tooltip: 'setup',
              ),
            ],
          ),
          body: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _buildRow(context, items[i]);
              })),
    );
  }

  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = _prefs.getString('server') ?? '';
      _streamId = _prefs.getString('streamId') ?? 'Enter stream id';
    });
  }

  void showStreamIdDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          var settedIP = _prefs.getString('server');
          _prefs.setString('streamId', _streamId);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _play == true
                      ? CallSample(ip: settedIP, type: 'play', id: _streamId)
                      : CallSample(
                          ip: settedIP, type: 'publish', id: _streamId)));
        }
      }
    });
  }

  void showServerAddressDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
    });
  }

  void _showToastServer(BuildContext context) {
    if (_server == '' || _server == null) {
      Get.snackbar('Warning', 'Set the server address first',
          barBlur: 1,
          dismissDirection: SnackDismissDirection.VERTICAL,
          backgroundColor: Colors.redAccent,
          overlayBlur: 1,
          animationDuration: Duration(milliseconds: 500),
          duration: Duration(seconds: 2));
    } else if (_server != '') {
      Get.snackbar('Success!', 'Server Address has been set successfully',
          barBlur: 1,
          backgroundColor: Colors.greenAccent,
          dismissDirection: SnackDismissDirection.VERTICAL,
          overlayBlur: 1,
          animationDuration: Duration(milliseconds: 500),
          duration: Duration(seconds: 2));
    }
  }

  void _showToastStream(BuildContext context) {
    if (_streamId == '' || _streamId == 'Enter stream id') {
      Get.snackbar('Warning', 'Set the stream id',
          barBlur: 1,
          dismissDirection: SnackDismissDirection.VERTICAL,
          backgroundColor: Colors.redAccent,
          overlayBlur: 1,
          animationDuration: Duration(milliseconds: 500),
          duration: Duration(seconds: 2));
    }
  }

  _showStreamIdDialog(context) {
    if (_server == '') {
      _showToastServer(context);
    } else {
      var _controller = TextEditingController();
      showStreamIdDialog<DialogDemoAction>(
          context: context,
          child: AlertDialog(
              title: const Text('Enter stream id'),
              content: TextField(
                onChanged: (String text) {
                  setState(() {
                    _streamId = text;
                  });
                },
                controller: _controller,
                decoration: InputDecoration(
                  hintText: _streamId,
                  suffixIcon: IconButton(
                    onPressed: () => _controller.clear(),
                    icon: Icon(Icons.clear),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              actions: <Widget>[
                FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, DialogDemoAction.cancel);
                    }),
                FlatButton(
                    child: const Text('Connect'),
                    onPressed: () {
                      if (_streamId == '' || _streamId == 'Enter stream id') {
                        _showToastStream(context);
                      } else {
                        Navigator.pop(context, DialogDemoAction.connect);
                      }
                    }),
              ]));
    }
  }

  _showServerAddressDialog(context) {
    var _controller = TextEditingController();
    final context = navigatorKey.currentState.overlay.context;
    showServerAddressDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text(
                'Enter Stream Address using the following format:\nhttps://domain:port/WebRTCAppEE/websocket'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _server = text;
                });
              },
              controller: _controller,
              decoration: InputDecoration(
                hintText: _server == ''
                    ? 'https://domain:port/WebRTCAppEE/websocket'
                    : _server,
                suffixIcon: IconButton(
                  onPressed: () => _controller.clear(),
                  icon: Icon(Icons.clear),
                ),
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              FlatButton(
                  child: const Text('Set Server Ip'),
                  onPressed: () {
                    _prefs.setString('server', _server);
                    _showToastServer(context);
                    if (_server != '')
                      Future.delayed(Duration(milliseconds: 2400),
                          () => Navigator.pop(context));
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[

      RouteItem(
          title: 'Play',
          subtitle: 'Play',
          push: (BuildContext context) {
            _play = true;
            _showStreamIdDialog(context);
          }),
      RouteItem(
          title: 'Publish',
          subtitle: 'Publish',
          push: (BuildContext context) {
            _play = false;
            _showStreamIdDialog(context);
          }),
    ];
  }
}

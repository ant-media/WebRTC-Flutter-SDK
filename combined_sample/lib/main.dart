// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:core';
import 'dart:io';
import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sample/route_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

void main() => runApp(const MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    ));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MyAppState extends State<MyApp> {
  List<RouteItem> items = [];
  String _server = '';
  late SharedPreferences _prefs;
  String _streamId = '';
  final navigatorKey = GlobalKey<NavigatorState>();
  bool _publish = false;
  bool _play = false;
  bool _p2p = false;
  bool _conference = false;

  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
    AntMediaFlutter.requestPermissions();

    if (Platform.isAndroid) {
      AntMediaFlutter.startForegroundService();
    }
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: const Icon(Icons.arrow_right),
      ),
      const Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Ant Media Server Example'),
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

  void showStreamIdDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          String? settedIP = _prefs.getString('server');
          _prefs.setString('streamId', _streamId);
          if (settedIP != null) {
            if (_publish == true) {
              showRecordOptions(context);
            } else if (_play == true) {
              AntMediaFlutter.playWith(_streamId, settedIP, false, context);
            } else if (_p2p == true) {
              AntMediaFlutter.starPeerConnectionwithStreamId(
                  _streamId, settedIP, false, context);
            } else if (_conference == true) {
              AntMediaFlutter.startConferenceWithStreamId(
                  _streamId, 'roomId' ,settedIP, false, context);
            }
          }
        }
      }
    });
  }

  void showServerAddressDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
    });
  }

  // Future<bool> startForegroundService() async {
  //   final androidConfig = FlutterBackgroundAndroidConfig(
  //     notificationTitle: 'Title of the notification',
  //     notificationText: 'Text of the notification',
  //     notificationImportance: AndroidNotificationImportance.Default,
  //     notificationIcon:
  //         AndroidResource(name: 'background_icon', defType: 'drawable'),
  //   );
  //   await FlutterBackground.initialize(androidConfig: androidConfig);
  //   return FlutterBackground.enableBackgroundExecution();
  // }

  void _showToastServer(BuildContext context) {
    if (_server == '') {
      Get.snackbar('Warning', 'Set the server address first',
          barBlur: 1,
          backgroundColor: Colors.redAccent,
          overlayBlur: 1,
          animationDuration: const Duration(milliseconds: 500),
          duration: const Duration(seconds: 2));
    } else if (_server != '') {
      Get.snackbar('Success!', 'Server Address has been set successfully',
          barBlur: 1,
          backgroundColor: Colors.greenAccent,
          overlayBlur: 1,
          animationDuration: const Duration(milliseconds: 500),
          duration: const Duration(seconds: 2));
    }
  }

  void _showToastStream(BuildContext context) {
    if (_streamId == '' || _streamId == 'Enter stream id') {
      Get.snackbar('Warning', 'Set the stream id',
          barBlur: 1,
          backgroundColor: Colors.redAccent,
          overlayBlur: 1,
          animationDuration: const Duration(milliseconds: 500),
          duration: const Duration(seconds: 2));
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
                    icon: const Icon(Icons.clear),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              actions: <Widget>[
                MaterialButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true)
                          .pop(DialogDemoAction.cancel);
                    }),
                MaterialButton(
                    child: const Text('Connect'),
                    onPressed: () {
                      if (_streamId == '' || _streamId == 'Enter stream id') {
                        _showToastStream(context);
                      } else {
                        Navigator.of(context, rootNavigator: true)
                            .pop(DialogDemoAction.connect);
                      }
                    }),
              ]));
    }
  }

  void _showServerAddressDialog(BuildContext context) {
    var _controller = TextEditingController();
    //final context = navigatorKey.currentState?.overlay?.context;
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
                  icon: const Icon(Icons.clear),
                ),
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              MaterialButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              MaterialButton(
                  child: const Text('Set Server Ip'),
                  onPressed: () {
                    _prefs.setString('server', _server);
                    _showToastServer(context);
                    if (_server != '') {
                      Future.delayed(const Duration(milliseconds: 2400),
                          () => Navigator.pop(context));
                    }
                  })
            ]));
  }

  void showRecordOptions(BuildContext context) {
    //final context = navigatorKey.currentState?.overlay?.context;
    showServerAddressDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text('Choose the Publishing Source'),
            actions: <Widget>[
              MaterialButton(
                  child: const Text('Camera'),
                  onPressed: () {
                    String? settedIP = _prefs.getString('server');
                    if (settedIP != null) {
                      AntMediaFlutter.publishWith(
                          _streamId, false, settedIP, context);
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }),
              MaterialButton(
                  child: const Text('Screen'),
                  onPressed: () {
                    String? settedIP = _prefs.getString('server');
                    if (settedIP != null) {
                      AntMediaFlutter.publishWith(
                          _streamId, true, settedIP, context);
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'Play',
          subtitle: 'Play',
          push: (BuildContext context) {
            _publish = false;
            _play = true;
            _p2p = false;
            _conference = false;
            _showStreamIdDialog(context);
          }),
      RouteItem(
          title: 'Publish',
          subtitle: 'Publish',
          push: (BuildContext context) {
            _publish = true;
            _play = false;
            _p2p = false;
            _conference = false;
            _showStreamIdDialog(context);
          }),
      RouteItem(
          title: 'P2P',
          subtitle: 'Peer to Peer',
          push: (BuildContext context) {
            _publish = false;
            _play = false;
            _p2p = true;
            _conference = false;

            _showStreamIdDialog(context);
          }),
      RouteItem(
          title: 'Conference',
          subtitle: 'Conference call',
          push: (BuildContext context) {
            _publish = false;
            _play = false;
            _p2p = false;
            _conference = true;

            _showStreamIdDialog(context);
          })
    ];
  }
}

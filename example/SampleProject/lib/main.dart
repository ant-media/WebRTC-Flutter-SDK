// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:core';

import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:example/conference.dart';
import 'package:example/datachannel.dart';
import 'package:example/peer.dart';
import 'package:example/play.dart';
import 'package:example/publish.dart';
import 'package:example/route_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

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
  bool _datachannel = false;

  String _roomId = '';

  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
    AntMediaFlutter.requestPermissions();

    if (!kIsWeb && Platform.isAndroid) {
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
                  _shoWserverAddressDialog(context);
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

  void shoWstreamIdDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          String? settedIP = _prefs.getString('server');
          _prefs.setString('streamId', _streamId);
          if (settedIP != null) {
            if (_publish == true) {
              showRecordOptions(context);
            } else if (_play == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => Play(
                            ip: settedIP,
                            id: _streamId,
                            userscreen: false,
                          )));
            } else if (_p2p == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => Peer(
                            ip: settedIP,
                            id: _streamId,
                            userscreen: false,
                          )));
            } else if (_conference == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => Conference(
                            ip: settedIP,
                            id: _streamId,
                            userscreen: false,
                            roomId: _roomId,
                          )));
            } else if (_datachannel == true) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => DataChannel(
                            ip: settedIP,
                            id: _streamId,
                            userscreen: false,
                          )));
            }
          }
        }
      }
    });
  }

  void shoWserverAddressDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
    });
  }

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

  void _showToastRoom(BuildContext context) {
    if (_roomId == '' || _roomId == 'Enter room id') {
      Get.snackbar('Warning', 'Set the room id',
          barBlur: 1,
          backgroundColor: Colors.redAccent,
          overlayBlur: 1,
          animationDuration: const Duration(milliseconds: 500),
          duration: const Duration(seconds: 2));
    }
  }

  _shoWstreamAndRoomIdDialog(context) {
    if (_server == '') {
      _showToastServer(context);
    } else {
      final _streamidcontroller = TextEditingController();
      final _roomidcontroller = TextEditingController();
      shoWstreamIdDialog<DialogDemoAction>(
          context: context,
          child: AlertDialog(
              content: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Enter stream id',
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(
                        height: 0,
                      ),
                      TextField(
                        textAlign: TextAlign.start,
                        onChanged: (String text) {
                          setState(() {
                            _streamId = text;
                          });
                        },
                        controller: _streamidcontroller,
                        decoration: InputDecoration(
                          hintText: _streamId,
                          suffixIcon: IconButton(
                            onPressed: () => _streamidcontroller.clear(),
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text('Enter room id'),
                      TextField(
                        onChanged: (String text) {
                          setState(() {
                            _roomId = text;
                          });
                        },
                        controller: _roomidcontroller,
                        decoration: InputDecoration(
                          hintText: _roomId,
                          suffixIcon: IconButton(
                            onPressed: () => _roomidcontroller.clear(),
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  )),
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
                      } else if (_roomId == '' || _roomId == 'Enter room id') {
                        _showToastRoom(context);
                      } else {
                        Navigator.of(context, rootNavigator: true)
                            .pop(DialogDemoAction.connect);
                      }
                    }),
              ]));
    }
  }

  _shoWstreamIdDialog(context) {
    if (_server == '') {
      _showToastServer(context);
    } else {
      var _controller = TextEditingController();
      shoWstreamIdDialog<DialogDemoAction>(
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

  void _shoWserverAddressDialog(BuildContext context) {
    var _controller = TextEditingController();
    //final context = navigatorKey.currentState?.overlay?.context;
    shoWserverAddressDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text(
                'Enter Stream Address using the following format:\ wss://domain:port/WebRTCAppEE/websocket'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _server = text;
                });
              },
              controller: _controller,
              decoration: InputDecoration(
                hintText: _server == ''
                    ? 'wss://domain:port/WebRTCAppEE/websocket'
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
    shoWserverAddressDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
            title: const Text('Choose the Publishing Source'),
            actions: <Widget>[
              MaterialButton(
                  child: const Text('Camera'),
                  onPressed: () {
                    String? settedIP = _prefs.getString('server');
                    if (settedIP != null) {
                      {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) => Publish(
                                      ip: settedIP,
                                      id: _streamId,
                                      userscreen: false,
                                    )));
                      }
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }),
              MaterialButton(
                  child: const Text('Screen'),
                  onPressed: () {
                    String? settedIP = _prefs.getString('server');
                    if (settedIP != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => Publish(
                                    ip: settedIP,
                                    id: _streamId,
                                    userscreen: true,
                                  )));

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
            _datachannel = false;
            _shoWstreamIdDialog(context);
          }),
      RouteItem(
          title: 'Publish',
          subtitle: 'Publish',
          push: (BuildContext context) {
            _publish = true;
            _play = false;
            _p2p = false;
            _conference = false;
            _datachannel = false;
            _shoWstreamIdDialog(context);
          }),
      RouteItem(
          title: 'P2P',
          subtitle: 'Peer to Peer',
          push: (BuildContext context) {
            _publish = false;
            _play = false;
            _p2p = true;
            _conference = false;
            _datachannel = false;

            _shoWstreamIdDialog(context);
          }),
      RouteItem(
          title: 'Conference',
          subtitle: 'Conference call',
          push: (BuildContext context) {
            _publish = false;
            _play = false;
            _p2p = false;
            _conference = true;
            _datachannel = false;

            _shoWstreamAndRoomIdDialog(context);
          }),
      RouteItem(
          title: 'DataChannel',
          subtitle: 'DataChannel',
          push: (BuildContext context) {
            _publish = false;
            _play = false;
            _p2p = false;
            _conference = false;
            _datachannel = true;

            _shoWstreamIdDialog(context);
          })
    ];
  }
}

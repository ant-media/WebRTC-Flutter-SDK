// // ignore_for_file: import_of_legacy_library_into_null_safe

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

  @override
  initState() {
    super.initState();
    _initData();


    // // ignore_for_file: import_of_legacy_library_into_null_safe
//
// import 'dart:core';
// import 'dart:io';
// import 'package:ant_media_flutter/ant_media_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:sample/route_item.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:get/get.dart';
//
// void main() => runApp(const MaterialApp(
//       home: MyApp(),
//       debugShowCheckedModeBanner: false,
//     ));
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// enum DialogDemoAction {
//   cancel,
//   connect,
// }
//
// class _MyAppState extends State<MyApp> {
//   List<RouteItem> items = [];
//   String _server = '';
//   late SharedPreferences _prefs;
//   String _streamId = '';
//   final navigatorKey = GlobalKey<NavigatorState>();
//
//   @override
//   initState() {
//     super.initState();
//     _initData();
//     _initItems();
//     AntMediaFlutter.requestPermissions();
//
//     if (Platform.isAndroid) {
//       AntMediaFlutter.startForegroundService();
//     }
//
//   }
//
//   _buildRow(context, item) {
//     return ListBody(children: <Widget>[
//       ListTile(
//         title: Text(item.title),
//         onTap: () => item.push(context),
//         trailing: const Icon(Icons.arrow_right),
//       ),
//       const Divider()
//     ]);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       navigatorKey: navigatorKey,
//       home: Scaffold(
//           appBar: AppBar(
//             title: const Text('Ant Media Server Example'),
//             actions: <Widget>[
//               IconButton(
//                 icon: const Icon(Icons.settings),
//                 onPressed: () {
//                   _showServerAddressDialog(context);
//                 },
//                 tooltip: 'setup',
//               ),
//             ],
//           ),
//           body: ListView.builder(
//               shrinkWrap: true,
//               padding: const EdgeInsets.all(0.0),
//               itemCount: items.length,
//               itemBuilder: (context, i) {
//                 return _buildRow(context, items[i]);
//               })),
//     );
//   }
//
//   _initData() async {
//     _prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _server = _prefs.getString('server') ?? '';
//       _streamId = _prefs.getString('streamId') ?? 'Enter stream id';
//     });
//   }
//
//   void showStreamIdDialog<T>(
//       {required BuildContext context, required Widget child}) {
//     showDialog<T>(
//       context: context,
//       builder: (BuildContext context) => child,
//     ).then<void>((T? value) {
//       // The value passed to Navigator.pop() or null.
//       if (value != null) {
//         if (value == DialogDemoAction.connect) {
//           String? settedIP = _prefs.getString('server');
//           _prefs.setString('streamId', _streamId);
//           if (settedIP != null) {
//             showRecordOptions(context);
//           }
//         }
//       }
//     });
//   }
//
//   void showServerAddressDialog<T>(
//       {required BuildContext context, required Widget child}) {
//     showDialog<T>(
//       context: context,
//       builder: (BuildContext context) => child,
//     ).then<void>((T? value) {
//       // The value passed to Navigator.pop() or null.
//     });
//   }
//
//   void _showToastServer(BuildContext context) {
//     if (_server == '') {
//       Get.snackbar('Warning', 'Set the server address first',
//           barBlur: 1,
//           backgroundColor: Colors.redAccent,
//           overlayBlur: 1,
//           animationDuration: const Duration(milliseconds: 500),
//           duration: const Duration(seconds: 2));
//     } else if (_server != '') {
//       Get.snackbar('Success!', 'Server Address has been set successfully',
//           barBlur: 1,
//           backgroundColor: Colors.greenAccent,
//           overlayBlur: 1,
//           animationDuration: const Duration(milliseconds: 500),
//           duration: const Duration(seconds: 2));
//     }
//   }
//
//   void _showToastStream(BuildContext context) {
//     if (_streamId == '' || _streamId == 'Enter stream id') {
//       Get.snackbar('Warning', 'Set the stream id',
//           barBlur: 1,
//           backgroundColor: Colors.redAccent,
//           overlayBlur: 1,
//           animationDuration: const Duration(milliseconds: 500),
//           duration: const Duration(seconds: 2));
//     }
//   }
//
//   _showStreamIdDialog(context) {
//     if (_server == '') {
//       _showToastServer(context);
//     } else {
//       var _controller = TextEditingController();
//       showStreamIdDialog<DialogDemoAction>(
//           context: context,
//           child: AlertDialog(
//               title: const Text('Enter stream id'),
//               content: TextField(
//                 onChanged: (String text) {
//                   setState(() {
//                     _streamId = text;
//                   });
//                 },
//                 controller: _controller,
//                 decoration: InputDecoration(
//                   hintText: _streamId,
//                   suffixIcon: IconButton(
//                     onPressed: () => _controller.clear(),
//                     icon: const Icon(Icons.clear),
//                   ),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               actions: <Widget>[
//                 MaterialButton(
//                     child: const Text('Cancel'),
//                     onPressed: () {
//                       Navigator.of(context, rootNavigator: true)
//                           .pop(DialogDemoAction.cancel);
//                     }),
//                 MaterialButton(
//                     child: const Text('Connect'),
//                     onPressed: () {
//                       if (_streamId == '' || _streamId == 'Enter stream id') {
//                         _showToastStream(context);
//                       } else {
//                         Navigator.of(context, rootNavigator: true)
//                             .pop(DialogDemoAction.connect);
//                       }
//                     }),
//               ]));
//     }
//   }
//
//   void _showServerAddressDialog(BuildContext context) {
//     var _controller = TextEditingController();
//     //final context = navigatorKey.currentState?.overlay?.context;
//     showServerAddressDialog<DialogDemoAction>(
//         context: context,
//         child: AlertDialog(
//             title: const Text(
//                 'Enter Stream Address using the following format:\nhttps://domain:port/WebRTCAppEE/websocket'),
//             content: TextField(
//               onChanged: (String text) {
//                 setState(() {
//                   _server = text;
//                 });
//               },
//               controller: _controller,
//               decoration: InputDecoration(
//                 hintText: _server == ''
//                     ? 'https://domain:port/WebRTCAppEE/websocket'
//                     : _server,
//                 suffixIcon: IconButton(
//                   onPressed: () => _controller.clear(),
//                   icon: const Icon(Icons.clear),
//                 ),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             actions: <Widget>[
//               MaterialButton(
//                   child: const Text('Cancel'),
//                   onPressed: () {
//                     Navigator.pop(context, DialogDemoAction.cancel);
//                   }),
//               MaterialButton(
//                   child: const Text('Set Server Ip'),
//                   onPressed: () {
//                     _prefs.setString('server', _server);
//                     _showToastServer(context);
//                     if (_server != '') {
//                       Future.delayed(const Duration(milliseconds: 2400),
//                           () => Navigator.pop(context));
//                     }
//                   })
//             ]));
//   }
//
//   void showRecordOptions(BuildContext context) {
//     //final context = navigatorKey.currentState?.overlay?.context;
//     showServerAddressDialog<DialogDemoAction>(
//         context: context,
//         child: AlertDialog(
//             title: const Text('Choose the Publishing Source'),
//             actions: <Widget>[
//               MaterialButton(
//                   child: const Text('Camera'),
//                   onPressed: () {
//                     String? settedIP = _prefs.getString('server');
//                     if (settedIP != null) {
//                       AntMediaFlutter.startDataChannelWith(
//                           _streamId, false, settedIP, context);
//                       Navigator.of(context, rootNavigator: true).pop();
//                     }
//                   }),
//               MaterialButton(
//                   child: const Text('Screen'),
//                   onPressed: () {
//                     String? settedIP = _prefs.getString('server');
//                     if (settedIP != null) {
//                       AntMediaFlutter.startDataChannelWith(
//                           _streamId, true, settedIP, context);
//                       Navigator.of(context, rootNavigator: true).pop();
//                     }
//                   })
//             ]));
//   }
//
//   _initItems() {
//     items = <RouteItem>[
//       RouteItem(
//           title: 'DataChannel',
//           subtitle: 'DataChannel',
//           push: (BuildContext context) {
//             _showStreamIdDialog(context);
//           }),
//     ];
//   }
// }


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
            showRecordOptions(context);
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
                'Enter Stream Address using the following format:\nwss://domain:port/WebRTCAppEE/websocket'),
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
                      AntMediaFlutter.startDataChannelWith(
                          _streamId, false, settedIP, context);
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  }),
              MaterialButton(
                  child: const Text('Screen'),
                  onPressed: () {
                    String? settedIP = _prefs.getString('server');
                    if (settedIP != null) {
                      AntMediaFlutter.startDataChannelWith(
                          _streamId, true, settedIP, context);
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'DataChannel',
          subtitle: 'DataChannel',
          push: (BuildContext context) {
            _showStreamIdDialog(context);
          }),
    ];
  }
}

//
// import 'dart:core';
//
// import 'package:flutter/foundation.dart'
//     show debugDefaultTargetPlatformOverride;
// import 'package:flutter/material.dart';
// import 'package:flutter_background/flutter_background.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
//
// import 'src/data_channel_sample.dart';
// import 'src/get_display_media_sample.dart';
// import 'src/get_user_media_sample.dart'
// if (dart.library.html) 'src/get_user_media_sample_web.dart';
// import 'src/loopback_sample.dart';
// import 'src/loopback_sample_unified_tracks.dart';
// import 'src/route_item.dart';
//
// void main() {
//   if (WebRTC.platformIsDesktop) {
//     debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
//   } else if (WebRTC.platformIsAndroid) {
//     WidgetsFlutterBinding.ensureInitialized();
//     startForegroundService();
//   }
//   runApp(MyApp());
// }
//
// Future<bool> startForegroundService() async {
//   const androidConfig = FlutterBackgroundAndroidConfig(
//     notificationTitle: 'Title of the notification',
//     notificationText: 'Text of the notification',
//     notificationImportance: AndroidNotificationImportance.Default,
//     notificationIcon: AndroidResource(
//         name: 'background_icon',
//         defType: 'drawable'), // Default is ic_launcher from folder mipmap
//   );
//   await FlutterBackground.initialize(androidConfig: androidConfig);
//   return FlutterBackground.enableBackgroundExecution();
// }
//
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   late List<RouteItem> items;
//
//   @override
//   void initState() {
//     super.initState();
//     _initItems();
//   }
//
//   ListBody _buildRow(context, item) {
//     return ListBody(children: <Widget>[
//       ListTile(
//         title: Text(item.title),
//         onTap: () => item.push(context),
//         trailing: Icon(Icons.arrow_right),
//       ),
//       Divider()
//     ]);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//           appBar: AppBar(
//             title: Text('Flutter-WebRTC example'),
//           ),
//           body: ListView.builder(
//               shrinkWrap: true,
//               padding: const EdgeInsets.all(0.0),
//               itemCount: items.length,
//               itemBuilder: (context, i) {
//                 return _buildRow(context, items[i]);
//               })),
//     );
//   }
//
//   void _initItems() {
//     items = <RouteItem>[
//       RouteItem(
//           title: 'GetUserMedia',
//           push: (BuildContext context) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) => GetUserMediaSample()));
//           }),
//       RouteItem(
//           title: 'GetDisplayMedia',
//           push: (BuildContext context) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) =>
//                         GetDisplayMediaSample()));
//           }),
//       RouteItem(
//           title: 'LoopBack Sample',
//           push: (BuildContext context) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) => LoopBackSample()));
//           }),
//       RouteItem(
//           title: 'LoopBack Sample (Unified Tracks)',
//           push: (BuildContext context) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) =>
//                         LoopBackSampleUnifiedTracks()));
//           }),
//       RouteItem(
//           title: 'DataChannel',
//           push: (BuildContext context) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (BuildContext context) => DataChannelSample()));
//           }),
//     ];
//   }
// }
//

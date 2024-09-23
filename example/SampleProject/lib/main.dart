
import 'dart:core';
import 'package:ant_media_flutter/ant_media_flutter.dart';
import 'package:example/conference.dart';
import 'package:example/datachannel.dart';
import 'package:example/peer.dart';
import 'package:example/play.dart';
import 'package:example/publish.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  String setIP = '';
  String _server = '';
  String _streamId = '';
  String _roomId = '';

  bool setPublish = false;

  final navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey recordDialogKey = GlobalKey();


  @override
  initState() {
    super.initState();
    AntMediaFlutter.requestPermissions();
    if (!kIsWeb && Platform.isAndroid) {
      AntMediaFlutter.startForegroundService();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
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
        body: Column(
          children: [
            buildExampleItem(context, "Play", 0),
            customDivider(),
            buildExampleItem(context,"Publish", 1),
            customDivider(),
            buildExampleItem(context,"Peer to Peer",  2),
            customDivider(),
            buildExampleItem(context,"Conference",  3),
            customDivider(),
            buildExampleItem(context,"Data Channel",  4),
          ],
        ),);
  }

  Widget buildExampleItem(BuildContext context, String text, int selectedOption) {
    return GestureDetector(
      onTap: () {
        if (_server.isEmpty) {
          _showToastServer(context);
        } else {
        _navigateToSelected(context, selectedOption);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Future<void> _navigateToSelected(BuildContext context, int selectedOption) async {
    switch (selectedOption) {
      case 0:// Play
        await _showRoomIdDialog(context,0);
      case 1: // Publish
        showRecordOptions(context);
      case 2: // Peer to Peer
        await _showRoomIdDialog(context,1);
        case 3: // Conference
        await showStreamAndRoomIdDialog(context);
      case 4: // Data Channel
        _showRoomIdDialog(context, 2);
      default:
        print("Unknown option");
    }
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
    final showToastServer = SnackBar(
      content: Text(
        _server == ''
            ? 'Set the server address first'
            : 'Server Address has been set successfully',
      ),
      backgroundColor: _server == '' ? Colors.redAccent : Colors.greenAccent,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.all(16.0),
    );
    ScaffoldMessenger.of(context).showSnackBar(showToastServer);
  }


  void _showServerAddressDialog(BuildContext context) {
    var _controller = TextEditingController();
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
                    setState(() {
                    _server = _controller.text;
                    });
                    if (_server != '') {
                    _showToastServer(context);
                      Navigator.pop(context);
                    }
                  })
            ]));
  }

  Future<String?> _showRoomIdDialog(BuildContext context, int index) async {
    final TextEditingController roomIdController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Room ID"),
          content: TextField(
            controller: roomIdController,
            onChanged: (String text){
              setState(() {
                _roomId = text;
              });
            },
            decoration: const InputDecoration(
              labelText: "Room ID",
              hintText: "Enter room ID",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_roomId != ""){
                  navigateToAppropriatePage(index);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void navigateToAppropriatePage(int index){
    switch(index){
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => Play(
              ip: _server,
              id: _roomId,
              userscreen: false,
            ),
          ),
        );
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                Peer(
                  ip: setIP,
                  id: _streamId,
                  userscreen: false,
                ),
          ),
        );
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => DataChannel(
              ip: setIP,
              id: _streamId,
              userscreen: false,
            ),
          ),
        );
    }
  }

  void showRecordOptions(BuildContext context) {
    shoWserverAddressDialog<DialogDemoAction>(
        context: context,
        child: AlertDialog(
          key: recordDialogKey,
            title: const Text('Choose the Publishing Source'),
            actions: <Widget>[
              MaterialButton(
                  child: const Text('Camera'),
                  onPressed: () {
                    {
                      setState(() {
                        setPublish = true;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => Publish(
                                    ip: setIP,
                                    id: _streamId,
                                    userscreen: false,
                                  )));
                    }
                    Navigator.of(context, rootNavigator: true).pop();
                                    }),
              MaterialButton(
                  child: const Text('Screen'),
                  onPressed: () {
                    setState(() {
                      setPublish = true;
                    });
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => Publish(
                                  ip: setIP,
                                  id: _streamId,
                                  userscreen: true,
                                )));

                    Navigator.of(context, rootNavigator: true).pop();
                                    })
            ]));
  }

  Future<Map<String, String>?> showStreamAndRoomIdDialog(BuildContext context) async {
    final TextEditingController _streamIdController = TextEditingController();
    final TextEditingController _roomIdController = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect to Stream'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter stream ID'),
              TextField(
                controller: _streamIdController,
                onChanged: (String text){
                  setState(() {
                    _streamId = text;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Stream ID',
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Enter room ID'),
              TextField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  hintText: 'Room ID',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel, return nothing
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => Conference(
                      ip: _roomIdController.text,
                      id: _streamIdController.text,
                      userscreen: false,
                      roomId: _roomId,
                    ),
                  ),
                );
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  Widget customDivider(){
    return const Divider(color: Colors.black, thickness: 1);
  }
}

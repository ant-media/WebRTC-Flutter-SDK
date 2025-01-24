import 'package:firebase_messaging/firebase_messaging.dart';

// You can configure the firebase push notifications with flutter-fire (https://firebase.flutter.dev/docs/overview) after which you can use it in the example app like this:

//import 'package:ant_media_flutter/firebase_api.dart';

// void main() async{
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   await FirebaseApi().initNotifications();
//   return runApp(
//       const MaterialApp(
//         home: MyApp(),
//         debugShowCheckedModeBanner: false,
//       )
//   );
// }


Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Payload: ${message.data}");
}

Future<void> handleForegroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Payload: ${message.data}");
}

class FirebaseApi{

  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');
    await FirebaseMessaging.instance.subscribeToTopic("antmedia");
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
  }
}
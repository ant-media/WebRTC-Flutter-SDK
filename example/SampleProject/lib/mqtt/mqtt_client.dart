import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final client = MqttServerClient('192.168.1.100', 'FlutterClientId'); // Replace with the IP address of your Flask server

Future<int> connect() async {
  client.logging(on: true); // Enable logging for debugging
  client.setProtocolV311(); // Use MQTT v3.1.1
  client.keepAlivePeriod = 20; // Keep-alive interval in seconds
  client.connectTimeoutPeriod = 2000; // Timeout in milliseconds

  final connMess = MqttConnectMessage()
      .withClientIdentifier('FlutterClientId') // Unique identifier for this client
      .startClean()
      .withWillTopic('disconnected') // Optional, for the last will message
      .withWillMessage('The client has disconnected')
      .withWillQos(MqttQos.atLeastOnce);
  client.connectionMessage = connMess;

  try {
    print('Connecting to the MQTT broker...');
    await client.connect();
  } catch (e) {
    print('ERROR::Failed to connect to MQTT broker: $e');
    return -1; // Exit with an error code
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Connected to the broker!');
  } else {
    print('Connection failed - ${client.connectionStatus}');
    client.disconnect();
    return -1;
  }

  // Subscribe to the Flask app's MQTT topic
  const topic = 'webhook/data';
  print('Subscribing to $topic...');
  client.subscribe(topic, MqttQos.atMostOnce);

  // Handle incoming messages
  client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
    final recMessage = messages![0].payload as MqttPublishMessage;
    final payload =
    MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
    print('Received message: $payload on topic: ${messages[0].topic}');
  });

  return 0;
}

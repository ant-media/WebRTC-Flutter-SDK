// ignore_for_file: prefer_generic_function_type_aliases, constant_identifier_names

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'ant_media_flutter.dart';

/// A web implementation of the AntMediaFlutter plugin.
class AntMediaFlutterWebPlugin {
  static void registerWith(Registrar registrar) {
    // ignore: unused_local_variable
    final MethodChannel channel = MethodChannel(
      'com.ant_media_flutter/ant_media_flutter',
      const StandardMethodCodec(),
      registrar, // the registrar is used as the BinaryMessenger
    );
    // ignore: unused_local_variable
    final AntMediaFlutter instance = AntMediaFlutter();
  }
}

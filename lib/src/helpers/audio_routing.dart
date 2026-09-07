// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Apple (iOS/macOS) audio session routing.
///
/// flutter_webrtc leaves the session at the WebRTC default of category
/// `playAndRecord` + mode `voiceChat`, which routes output to the receiver
/// (earpiece). To get the loudspeaker you need three things together:
///
///  * category `playAndRecord` — `defaultToSpeaker` is only valid here, and
///    `overrideOutputAudioPort` (what setSpeakerphoneOn calls) is rejected
///    under `playback`,
///  * the `defaultToSpeaker` option plus mode `videoChat`, both of which
///    select speaker output,
///  * applying it AFTER WebRTC's audio unit has started, because starting the
///    unit reconfigures the session and overwrites anything set earlier.
///
/// Every call is best effort: a failed audio session change must never take
/// the stream down with it.
class AntAudioRouting {
  AntAudioRouting._();

  static bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Whether we changed the session, so we only restore what we touched.
  static bool _applied = false;

  static final _speakerConfiguration = AppleAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.playAndRecord,
    appleAudioCategoryOptions: {
      AppleAudioCategoryOption.defaultToSpeaker,
      AppleAudioCategoryOption.allowBluetooth,
      AppleAudioCategoryOption.allowBluetoothA2DP,
    },
    appleAudioMode: AppleAudioMode.videoChat,
  );

  // Same category, but without defaultToSpeaker and in voiceChat mode, which
  // is what puts output back on the receiver.
  static final _earpieceConfiguration = AppleAudioConfiguration(
    appleAudioCategory: AppleAudioCategory.playAndRecord,
    appleAudioCategoryOptions: {
      AppleAudioCategoryOption.allowBluetooth,
      AppleAudioCategoryOption.allowBluetoothA2DP,
    },
    appleAudioMode: AppleAudioMode.voiceChat,
  );

  /// Route output to the receiver/earpiece.
  ///
  /// Clearing the port override alone is not enough: defaultToSpeaker lives in
  /// the session configuration and keeps forcing the speaker, so the config
  /// has to be rewritten without it first.
  static Future<void> routeToEarpiece() async {
    if (!_isApple) return;
    try {
      await Helper.setAppleAudioConfiguration(_earpieceConfiguration);
      await Helper.setSpeakerphoneOn(false);
      _applied = true;
    } catch (e) {
      print('AntMedia: could not route audio to earpiece: $e');
    }
  }

  /// Route output to the loudspeaker.
  ///
  /// Safe to call repeatedly; it is applied both when a session starts and
  /// again once the first remote track arrives.
  static Future<void> routeToSpeaker() async {
    if (!_isApple) return;
    try {
      await Helper.setAppleAudioConfiguration(_speakerConfiguration);
      // The category above permits overrideOutputAudioPort, so this now takes
      // effect instead of failing silently.
      await Helper.setSpeakerphoneOn(true);
      _applied = true;
    } catch (e) {
      print('AntMedia: could not route audio to speaker: $e');
    }
  }

  /// Hand the session back to the WebRTC default when the call ends.
  static Future<void> restoreDefaultRouting() async {
    if (!_isApple || !_applied) return;
    try {
      await Helper.setAppleAudioIOMode(AppleAudioIOMode.localAndRemote);
      _applied = false;
    } catch (e) {
      print('AntMedia: could not restore audio routing: $e');
    }
  }

  /// Force output to the loudspeaker or back to the receiver/earpiece.
  static Future<void> setSpeakerphoneOn(bool enable) async {
    if (kIsWeb) return;
    print('SPEAKERBTN routing -> ${enable ? 'speaker' : 'earpiece'}');
    if (enable) {
      await routeToSpeaker();
    } else {
      await routeToEarpiece();
    }
  }
}

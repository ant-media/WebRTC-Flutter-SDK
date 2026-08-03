// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Apple (iOS/macOS) audio session routing.
///
/// flutter_webrtc leaves the audio session at the WebRTC default of category
/// `playAndRecord` + mode `voiceChat`, which routes output to the receiver
/// (earpiece). That is the right profile for a call, but wrong for playback:
/// [AntMediaType.Play] never opens the microphone, so it has no business in a
/// record-capable session and should behave like any other media player.
///
/// Every call here is best effort. A failed audio session change must never
/// take the stream down with it, so failures are logged and swallowed.
class AntAudioRouting {
  AntAudioRouting._();

  static bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Whether we changed the session, so we only restore what we touched.
  static bool _applied = false;

  /// Category `playback` + mode `spokenAudio`: loudspeaker output, no input,
  /// and no microphone-in-use indicator.
  static Future<void> applyPlaybackRouting() async {
    if (!_isApple) return;
    try {
      await Helper.setAppleAudioIOMode(
        AppleAudioIOMode.remoteOnly,
        preferSpeakerOutput: true,
      );
      _applied = true;
    } catch (e) {
      print('AntMedia: could not apply playback audio routing: $e');
    }
  }

  /// Restore a capture capable session.
  ///
  /// The audio session is process wide, so leaving it on `playback` after a
  /// playback session ends would leave a later publish or conference with a
  /// dead microphone.
  static Future<void> restoreDefaultRouting() async {
    if (!_isApple || !_applied) return;
    try {
      await Helper.setAppleAudioIOMode(AppleAudioIOMode.localAndRemote);
      _applied = false;
    } catch (e) {
      print('AntMedia: could not restore audio routing: $e');
    }
  }

  /// Force output to the loudspeaker or back to the receiver.
  static Future<void> setSpeakerphoneOn(bool enable) async {
    if (kIsWeb) return;
    try {
      await Helper.setSpeakerphoneOn(enable);
    } catch (e) {
      print('AntMedia: could not set speakerphone: $e');
    }
  }
}

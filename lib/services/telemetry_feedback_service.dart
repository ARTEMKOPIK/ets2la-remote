/// Fans [TelemetryProvider.events] out to two channels:
/// - a small "haptic language" (different vibration patterns for autopilot
///   on/off, ACC on/off, speed-limit crossed), and
/// - a text-to-speech announcer ("Autopilot on", "Over the limit").
///
/// Both are opt-in via `AppSettings` and both respect the reduce-motion
/// affordance (haptics stay silent under reduce-motion regardless of the
/// feature flag — the same policy [AppHaptics] already uses for button
/// feedback).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/telemetry_event.dart';
import '../providers/settings_provider.dart';
import '../providers/telemetry_provider.dart';

class TelemetryFeedbackService {
  TelemetryFeedbackService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  StreamSubscription<TelemetryEvent>? _sub;
  bool _ttsInitialised = false;

  /// Throttle rapid duplicate events — if the ETS2LA backend spams us
  /// with a flapping autopilot state we don't want the phone to buzz
  /// every 200 ms.
  final Map<TelemetryEventKind, DateTime> _lastEmitted = {};
  static const Duration _minGap = Duration(milliseconds: 600);

  /// Start listening to [provider] events and emit haptics/TTS per
  /// [settings]. Returns a disposer that cancels the subscription and
  /// stops any in-flight TTS.
  VoidCallback attach(TelemetryProvider provider, AppSettings settings) {
    _sub?.cancel();
    _sub = provider.events.listen((event) => _handle(event, settings));
    return dispose;
  }

  Future<void> _handle(TelemetryEvent event, AppSettings settings) async {
    final last = _lastEmitted[event.kind];
    final now = DateTime.now();
    if (last != null && now.difference(last) < _minGap) return;
    _lastEmitted[event.kind] = now;

    if (settings.hapticEventsEnabled && !settings.reduceMotion) {
      unawaited(_vibrate(event.kind));
    }
    if (settings.ttsEnabled) {
      unawaited(_speak(event));
    }
  }

  Future<void> _vibrate(TelemetryEventKind kind) async {
    try {
      switch (kind) {
        case TelemetryEventKind.steeringEnabled:
        case TelemetryEventKind.accEnabled:
        case TelemetryEventKind.collisionEnabled:
          // Short single tick — "engaged".
          await HapticFeedback.mediumImpact();
          break;
        case TelemetryEventKind.steeringDisabled:
        case TelemetryEventKind.accDisabled:
        case TelemetryEventKind.collisionDisabled:
          // Two heavy pulses — "lost". Back-to-back via a small gap so the
          // user can tell the difference from an enable.
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 140));
          await HapticFeedback.heavyImpact();
          break;
        case TelemetryEventKind.overSpeedLimit:
          // Sharp triple selection click — "warning, you're over".
          for (var i = 0; i < 3; i++) {
            await HapticFeedback.selectionClick();
            await Future<void>.delayed(const Duration(milliseconds: 70));
          }
          break;
        case TelemetryEventKind.backUnderSpeedLimit:
          // Soft tick — "all good again".
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (e) {
      debugPrint('TelemetryFeedbackService vibrate error: $e');
    }
  }

  Future<void> _ensureTtsReady() async {
    if (_ttsInitialised) return;
    _ttsInitialised = true;
    try {
      // Speak over music/game audio rather than pausing it; use the
      // Assistant audio channel on Android so ducking is short.
      await _tts.setSharedInstance(true);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Non-fatal — flutter_tts throws on iOS-only setters when running
      // on Android, and on some old Android images setSharedInstance
      // returns a PlatformException we can safely ignore.
    }
  }

  Future<void> _speak(TelemetryEvent event) async {
    await _ensureTtsReady();
    final phrase = _phraseFor(event);
    if (phrase == null) return;
    try {
      await _tts.stop();
      await _tts.speak(phrase);
    } catch (e) {
      debugPrint('TelemetryFeedbackService speak error: $e');
    }
  }

  String? _phraseFor(TelemetryEvent event) {
    switch (event.kind) {
      case TelemetryEventKind.steeringEnabled:
        return 'Autopilot on';
      case TelemetryEventKind.steeringDisabled:
        return 'Autopilot off';
      case TelemetryEventKind.accEnabled:
        return 'Cruise control on';
      case TelemetryEventKind.accDisabled:
        return 'Cruise control off';
      case TelemetryEventKind.collisionEnabled:
        return 'Collision avoidance on';
      case TelemetryEventKind.collisionDisabled:
        return 'Collision avoidance off';
      case TelemetryEventKind.overSpeedLimit:
        return 'Over the speed limit';
      case TelemetryEventKind.backUnderSpeedLimit:
        return null; // don't nag when returning to normal
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    unawaited(_tts.stop());
  }
}

/// Thin wrapper around [HapticFeedback] so callers don't need to remember
/// which Material intensity corresponds to which UX action.
///
/// Everything respects [AppSettings.reduceMotion] — when the user has opted
/// into the reduce-motion setting (or the OS-level equivalent on Android)
/// every haptic is silently a no-op. Motion and vibration share the same
/// user affordance in practice: someone who finds animations jarring
/// almost always finds unsolicited haptics jarring too.

import 'package:flutter/services.dart';

import '../providers/settings_provider.dart';

class AppHaptics {
  AppHaptics._();

  /// Light tap — cosmetic affordance for toggles / chips.
  static Future<void> light(AppSettings? settings) async {
    if (settings?.reduceMotion ?? false) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tap — confirmation for primary actions (connect, toggle
  /// autopilot / ACC, disconnect).
  static Future<void> medium(AppSettings? settings) async {
    if (settings?.reduceMotion ?? false) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap — destructive or error feedback.
  static Future<void> heavy(AppSettings? settings) async {
    if (settings?.reduceMotion ?? false) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — for picker-style widgets that "snap" between options.
  static Future<void> selection(AppSettings? settings) async {
    if (settings?.reduceMotion ?? false) return;
    await HapticFeedback.selectionClick();
  }
}

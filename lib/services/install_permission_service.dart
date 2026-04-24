/// Bridge to Android's per-app "Install unknown apps" toggle.
///
/// Declaring `REQUEST_INSTALL_PACKAGES` in the manifest is not sufficient on
/// Android 8+ — the user must also grant the setting manually. We expose
/// the current state and a helper to launch the matching Settings screen so
/// the update dialog can steer the user through it instead of silently
/// failing with a "Permission denied" error.

import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class InstallPermissionService {
  InstallPermissionService._();
  static final InstallPermissionService instance = InstallPermissionService._();

  static const MethodChannel _channel =
      MethodChannel('ets2la_remote/install_permission');

  /// Whether the app is currently allowed to launch Android's package
  /// installer. Always true on non-Android platforms (the caller is
  /// expected to guard its own APK-install flow by platform anyway).
  Future<bool> canInstall() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('canInstall');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Running against an old native build — assume not granted so the
      // dialog can show the help button instead of silently closing.
      return false;
    }
  }

  /// Open the system "Install unknown apps" settings page for this app.
  /// No-op on non-Android platforms.
  Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // Best effort; surfaced via canInstall() polling.
    } on MissingPluginException {
      // Old native build; nothing we can do here.
    }
  }
}

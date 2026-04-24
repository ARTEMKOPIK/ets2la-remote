/// Controls the Android foreground service that keeps the app process
/// promoted while connected to ETS2LA. Without it, the OS will kill the
/// Dart isolate (and therefore the WebSocket) a few minutes after the
/// screen turns off. iOS / desktop calls are silently no-ops.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class KeepAliveService {
  KeepAliveService._();
  static final KeepAliveService instance = KeepAliveService._();

  static const MethodChannel _channel =
      MethodChannel('ets2la_remote/keepalive');

  bool _running = false;
  bool get isRunning => _running;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> start(String host) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('start', {'host': host});
      _running = true;
    } on MissingPluginException {
      // Old APK running against a new channel — degrade silently.
    } on PlatformException catch (e) {
      debugPrint('KeepAliveService.start failed: ${e.message}');
    }
  }

  Future<void> update({required String title, required String body}) async {
    if (!_supported || !_running) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      // ignore — old APK or non-Android platform
    } on PlatformException catch (e) {
      debugPrint('KeepAliveService.update failed: ${e.message}');
    }
  }

  Future<void> stop() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // ignore — old APK or non-Android platform
    } on PlatformException catch (e) {
      debugPrint('KeepAliveService.stop failed: ${e.message}');
    } finally {
      _running = false;
    }
  }
}

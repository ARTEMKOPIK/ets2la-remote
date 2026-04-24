/// Bridge to Android launcher shortcuts (res/xml/shortcuts.xml).
///
/// Dart asks the native side for the pending tab index on cold start, and
/// listens for `shortcutTab` callbacks while the app is already running.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class ShortcutService {
  ShortcutService._() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'shortcutTab') {
          final tab = call.arguments;
          if (tab is int) _controller.add(tab);
        }
      });
    }
  }
  static final ShortcutService instance = ShortcutService._();

  static const MethodChannel _channel = MethodChannel('ets2la_remote/shortcut');
  final _controller = StreamController<int>.broadcast();

  /// Broadcast stream of tab indexes requested while the app is running
  /// (warm launch via launcher shortcut).
  Stream<int> get tabRequests => _controller.stream;

  /// Drain the cold-start shortcut tab, if any. Returns null on non-Android
  /// or when the activity wasn't started from a shortcut.
  Future<int?> getInitialTab() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<int>('getInitialTab');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

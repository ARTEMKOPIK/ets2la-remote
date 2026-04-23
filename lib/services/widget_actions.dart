/// Routes home-screen widget taps into live `PagesWsService` calls on the
/// currently-connected session.
///
/// The native side (see `AutopilotWidgetProvider.kt`) starts `MainActivity`
/// with an extra, which `MainActivity` forwards to Flutter as either:
///   - an initial action (drained once at app start via `getInitialAction`),
///   - or a live `widgetAction` method call (when the app is already
///     running and receives `onNewIntent`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Possible widget actions. Strings must match the ACTION_* constants in
/// `AutopilotWidgetProvider.kt`.
class WidgetAction {
  static const String toggleSteering =
      'com.ets2la.ets2la_remote.TOGGLE_STEERING';
  static const String toggleAcc = 'com.ets2la.ets2la_remote.TOGGLE_ACC';
}

typedef WidgetActionHandler = Future<void> Function(String action);

class WidgetActionBridge {
  WidgetActionBridge._();
  static final WidgetActionBridge instance = WidgetActionBridge._();

  static const MethodChannel _channel = MethodChannel('ets2la_remote/widget');

  WidgetActionHandler? _handler;

  /// Register a handler that will be invoked for each widget action. Only
  /// the most recent handler is kept so providers can reinstall it when
  /// they rebuild.
  void setHandler(WidgetActionHandler handler) {
    _handler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'widgetAction' && call.arguments is String) {
        await _dispatch(call.arguments as String);
      }
    });
    // Drain any action that arrived before we installed the handler (cold
    // start from the widget).
    unawaited(_drainInitial());
  }

  Future<void> _drainInitial() async {
    try {
      final action = await _channel.invokeMethod<String>('getInitialAction');
      if (action != null) await _dispatch(action);
    } on MissingPluginException {
      // Non-Android or older APK — no widget channel.
    } on PlatformException catch (e) {
      debugPrint('WidgetActionBridge.getInitialAction failed: ${e.message}');
    }
  }

  Future<void> _dispatch(String action) async {
    final handler = _handler;
    if (handler == null) return;
    try {
      await handler(action);
    } catch (e, st) {
      debugPrint('WidgetActionBridge handler error: $e\n$st');
    }
  }
}

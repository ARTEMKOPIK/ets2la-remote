/// WebSocket client for ETS2LA Pages server (port 37523).
/// Used to call plugin functions — including toggle autopilot/ACC.
library;

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'reconnect_backoff.dart';

class PagesWsService {
  static const int defaultPort = 37523;

  int get port => _port;

  void setPort(int port) => _port = port;

  WebSocketChannel? _channel;
  String? _host;
  int _port = defaultPort;
  bool _connected = false;
  bool _connecting = false;
  Timer? _reconnectTimer;
  final ReconnectBackoff _backoff = ReconnectBackoff();

  bool get isConnected => _connected;

  Future<void> connect(String host) async {
    _host = host;
    _reconnectTimer?.cancel();
    _backoff.reset();
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_connecting || _connected) return;
    _connecting = true;
    try {
      final uri = Uri.parse('ws://$_host:$_port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 5));
      _connected = true;
      _backoff.reset();
      _channel!.stream.listen(
        (_) {}, // we don't need responses
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
    } catch (_) {
      _onDisconnected();
    } finally {
      _connecting = false;
    }
  }

  /// Call a plugin function via the Pages WebSocket.
  /// [pageUrl] — the plugin's page URL (e.g. "/settings/map")
  /// [target]  — "Plugin.methodName" (e.g. "Plugin.on_toggle_map")
  /// [args]    — optional positional args
  ///
  /// Returns true only when the message was actually written to a live
  /// socket. Callers (dashboard toggles, widget, Wear OS) rely on this to
  /// show the firewall help dialog on failure.
  Future<bool> callFunction(String pageUrl, String target, {List<dynamic> args = const []}) async {
    if (!_connected) {
      await _doConnect();
    }
    final channel = _channel;
    if (!_connected || channel == null) return false;
    try {
      final msg = jsonEncode({
        'type': 'function',
        'data': {
          'url': pageUrl,
          'target': target,
          'args': args,
        },
      });
      channel.sink.add(msg);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle Map autopilot (steering).
  /// Signature: on_toggle_map(self, event_object, state: bool)
  /// event_object = null (not needed when calling directly), state = true
  Future<bool> toggleSteering() =>
      callFunction('/settings/map', 'Plugin.on_toggle_map', args: [null, true]);

  /// Toggle Adaptive Cruise Control.
  /// Signature: on_toggle_acc(self, event_object, state: bool)
  Future<bool> toggleAcc() =>
      callFunction('/settings/adaptivecruisecontrol', 'Plugin.on_toggle_acc', args: [null, true]);

  void _onDisconnected() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();
    if (_host == null) return; // disconnect() was called; don't schedule.
    _reconnectTimer = Timer(_backoff.nextDelay(), () {
      if (_host != null && !_connected) _doConnect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _host = null;
    _connected = false;
    _connecting = false;
    _backoff.reset();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() => disconnect();
}

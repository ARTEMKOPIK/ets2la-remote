import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/telemetry.dart';
import 'reconnect_backoff.dart';

class NavigationWsService {
  int _port = 62840; // Default, can be overridden
  int _readyTimeoutSeconds = 5;

  void setPort(int port) => _port = port;
  int get port => _port;

  /// Timeout for the WebSocket handshake. Clamped to [1, 60] s.
  void setReadyTimeoutSeconds(int seconds) {
    _readyTimeoutSeconds = seconds.clamp(1, 60);
  }

  WebSocketChannel? _channel;
  String? _host;
  Timer? _reconnectTimer;
  bool _connected = false;
  bool _connecting = false;
  final ReconnectBackoff _backoff = ReconnectBackoff();

  final _positionController = StreamController<NavPosition>.broadcast();
  final _routeController = StreamController<NavRoute>.broadcast();

  Stream<NavPosition> get positionStream => _positionController.stream;
  Stream<NavRoute> get routeStream => _routeController.stream;
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
      // Uri constructor bracketed IPv6 literals correctly.
      final uri = Uri(scheme: 'ws', host: _host, port: port);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready
          .timeout(Duration(seconds: _readyTimeoutSeconds));
      _connected = true;
      _backoff.reset();

      // Subscribe to channels
      _channel!.sink.add(jsonEncode([
        {'id': 1, 'params': {'path': 'onPositionUpdate'}},
        {'id': 2, 'params': {'path': 'onRouteUpdate'}},
      ]));

      _channel!.stream.listen(
        _handleIncomingFrame,
        onDone: _onDisconnected,
        onError: (Object e, StackTrace st) {
          debugPrint('NavWs error: $e\n$st');
          _onDisconnected();
        },
      );
    } catch (e, st) {
      debugPrint('NavWs _doConnect failed: $e\n$st');
      _onDisconnected();
    } finally {
      _connecting = false;
    }
  }

  /// Decode a single WS frame (text or binary) and forward to [_handleMessage].
  void _handleIncomingFrame(Object? raw) {
    try {
      final String text;
      if (raw is String) {
        text = raw;
      } else if (raw is List<int>) {
        text = utf8.decode(raw, allowMalformed: true);
      } else {
        return;
      }
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        _handleMessage(decoded);
      }
      // List payloads are subscription acks; nothing to do.
    } catch (e, st) {
      debugPrint('NavWs _handleIncomingFrame failed: $e\n$st');
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final result = msg['result'] as Map<String, dynamic>?;
    if (result == null) return;

    final type = result['type'] as String?;
    if (type != 'data') return;

    final data = result['data'];
    if (data == null || data is! Map<String, dynamic>) return;

    switch (msg['id'] as int?) {
      case 1: // onPositionUpdate
        _positionController.add(NavPosition.fromJson(data));
        break;
      case 2: // onRouteUpdate
        if (data.containsKey('segments')) {
          _routeController.add(NavRoute.fromJson(data));
        }
        break;
    }
  }

  void _onDisconnected() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
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

  void dispose() {
    disconnect();
    _positionController.close();
    _routeController.close();
  }
}

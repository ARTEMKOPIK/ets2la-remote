import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/telemetry.dart';

class NavigationWsService {
  int _port = 62840; // Default, can be overridden

  void setPort(int port) => _port = port;

  int get port => _port;

  WebSocketChannel? _channel;
  String? _host;
  Timer? _reconnectTimer;
  bool _connected = false;

  final _positionController = StreamController<NavPosition>.broadcast();
  final _routeController = StreamController<NavRoute>.broadcast();

  Stream<NavPosition> get positionStream => _positionController.stream;
  Stream<NavRoute> get routeStream => _routeController.stream;
  bool get isConnected => _connected;

  Future<void> connect(String host) async {
    _host = host;
    _reconnectTimer?.cancel();
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final uri = Uri.parse('ws://$_host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 5));
      _connected = true;

      // Subscribe to channels
      _channel!.sink.add(jsonEncode([
        {'id': 1, 'params': {'path': 'onPositionUpdate'}},
        {'id': 2, 'params': {'path': 'onRouteUpdate'}},
      ]));

      _channel!.stream.listen(
        (raw) {
          try {
            final decoded = jsonDecode(raw as String);
            // Can be a list (subscription responses) or a single object
            if (decoded is List) {
              // Subscription ack, ignore
            } else if (decoded is Map<String, dynamic>) {
              _handleMessage(decoded);
            }
          } catch (e) { debugPrint('NavigationWsService error: $e'); }
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
    } catch (e) {
      debugPrint('NavigationWsService connect error: $e');
      _onDisconnected();
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final id = msg['id'] as int?;
    final result = msg['result'] as Map<String, dynamic>?;
    if (result == null) return;

    final type = result['type'] as String?;
    if (type != 'data') return;

    final data = result['data'];
    if (data == null || data is! Map<String, dynamic>) return;

    switch (id) {
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
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_host != null && !_connected) _doConnect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _host = null;
    _connected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _positionController.close();
    _routeController.close();
  }
}

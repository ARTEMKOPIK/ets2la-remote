import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class VisualizationWsService {
  int _port = 37522; // Default, can be overridden

  void setPort(int port) => _port = port;

  int get port => _port;

  WebSocketChannel? _channel;
  // Single persistent broadcast controller — never replaced on reconnect.
  // TelemetryProvider subscribes once and always receives data.
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  WsConnectionState _state = WsConnectionState.disconnected;
  String? _host;
  Timer? _reconnectTimer;
  Timer? _keepAliveTimer;
  int _lastAck = 0;
  bool _subscribed = false;

  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;

  Future<void> connect(String host) async {
    _host = host;
    _reconnectTimer?.cancel();
    _keepAliveTimer?.cancel();
    _subscribed = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_state == WsConnectionState.connecting) return;
    _setState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('ws://$_host:$port');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready.timeout(const Duration(seconds: 5));

      // Set up stream listener FIRST to receive responses
      _lastAck = 0;
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(data); // always routes to the persistent stream
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - _lastAck > 100) {
              _send({'method': 'acknowledge', 'channel': 0});
              _lastAck = now;
            }
          } catch (e) { debugPrint("WebSocketService error: $e"); }
        },
        onDone: _onDisconnected,
        onError: (e) => _onDisconnected(),
      );

      // THEN set state and subscribe
      _setState(WsConnectionState.connected);
      _subscribeToChannels();
      
      // Start keep-alive timer
      _startKeepAlive();
    } catch (e) {
      _onDisconnected();
    }
  }

  void _subscribeToChannels() {
    if (_subscribed) return;
    _subscribed = true;
    _send({'method': 'acknowledge', 'channel': 0});
    _send({'method': 'subscribe', 'channel': 1}); // transform
    _send({'method': 'subscribe', 'channel': 3}); // truck state
    _send({'method': 'subscribe', 'channel': 7}); // autopilot status
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    // Only send acknowledge when there is pending data to acknowledge (throttled to 500ms)
    _keepAliveTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_state == WsConnectionState.connected && _channel != null) {
        _send({'method': 'acknowledge', 'channel': 0});
      }
    });
  }

  void _resubscribe() {
    // Re-subscribe after reconnect (but not on initial connect)
    if (_host != null) {
      _subscribed = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == WsConnectionState.connected) {
          _subscribeToChannels();
        }
      });
    }
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) { debugPrint("WebSocketService error: $e"); }
  }

  void _onDisconnected() {
    _keepAliveTimer?.cancel();
    _setState(WsConnectionState.disconnected);
    _channel?.sink.close();
    _channel = null;
    // Reset subscription flag so reconnect will resubscribe
    _subscribed = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_host != null && _state == WsConnectionState.disconnected) {
        _doConnect();
      }
    });
  }

  void _setState(WsConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _keepAliveTimer?.cancel();
    _host = null;
    _subscribed = false;
    _channel?.sink.close();
    _channel = null;
    // Do NOT close _controller — it's persistent, TelemetryProvider stays subscribed
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _controller.close();
    _stateController.close();
  }
}
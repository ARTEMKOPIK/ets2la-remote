import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'reconnect_backoff.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

/// WebSocket client for the ETS2LA visualization socket (default port 37522).
///
/// Decodes JSON frames and re-emits them on a *persistent* broadcast stream
/// so downstream providers can subscribe once and keep receiving data across
/// reconnects. Reconnect uses [ReconnectBackoff] (1s → 15s with jitter).
class VisualizationWsService {
  int _port = 37522;
  int _readyTimeoutSeconds = 5;

  void setPort(int port) => _port = port;
  int get port => _port;

  /// Timeout for the initial WebSocket handshake. Falls back to 5s if the
  /// caller never invokes this; clamped to [1, 60] s.
  void setReadyTimeoutSeconds(int seconds) {
    _readyTimeoutSeconds = seconds.clamp(1, 60);
  }

  WebSocketChannel? _channel;
  // Single persistent broadcast controller — never replaced on reconnect.
  // TelemetryProvider subscribes once and always receives data.
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  WsConnectionState _state = WsConnectionState.disconnected;
  String? _host;
  Timer? _reconnectTimer;
  Timer? _keepAliveTimer;
  bool _subscribed = false;
  final ReconnectBackoff _backoff = ReconnectBackoff();

  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  Stream<Map<String, dynamic>> get dataStream => _controller.stream;

  Future<void> connect(String host) async {
    _host = host;
    _reconnectTimer?.cancel();
    _keepAliveTimer?.cancel();
    _subscribed = false;
    _backoff.reset();
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_state == WsConnectionState.connecting ||
        _state == WsConnectionState.connected) {
      return;
    }
    _setState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('ws://$_host:$port');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready
          .timeout(Duration(seconds: _readyTimeoutSeconds));

      // Set up stream listener FIRST to receive responses
      _channel!.stream.listen(
        _handleIncomingFrame,
        onDone: _onDisconnected,
        onError: (Object _) => _onDisconnected(),
      );

      // THEN set state and subscribe
      _setState(WsConnectionState.connected);
      _backoff.reset();
      _subscribeToChannels();

      // Start keep-alive timer
      _startKeepAlive();
    } catch (_) {
      _onDisconnected();
    }
  }

  /// Decode an incoming frame to a `Map<String, dynamic>` and publish it on
  /// [dataStream]. Handles both text frames (the common case, emitted as
  /// `String` by `web_socket_channel`) and binary frames (emitted as
  /// `List<int>` / `Uint8List` — we UTF-8 decode them). Malformed payloads
  /// are dropped silently rather than bringing down the listener.
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
        _controller.add(decoded);
      }
    } catch (_) {
      // Ignore non-JSON frames; the periodic keep-alive timer will keep
      // the connection healthy even if the server emits garbage once.
    }
  }

  void _subscribeToChannels() {
    if (_subscribed) return;
    _subscribed = true;
    _send({'method': 'acknowledge', 'channel': 0});
    // Channel 1 (truck transform) is the highest-frequency stream ETS2LA
    // publishes; we don't render the truck mesh on the phone so skip the
    // subscription to save CPU and WS bandwidth. Re-add if a future screen
    // actually needs the transform.
    _send({'method': 'subscribe', 'channel': 3}); // truck state
    _send({'method': 'subscribe', 'channel': 7}); // autopilot status
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    // Periodic acknowledge keeps the ETS2LA Pages bridge alive when no data
    // frames are flowing (e.g. game paused). Frequency must be below the
    // server's idle timeout — 3s is safe. We rely on this single timer
    // instead of per-message acks so we don't spam the socket with ~10
    // writes per second in the steady state.
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_state == WsConnectionState.connected && _channel != null) {
        _send({'method': 'acknowledge', 'channel': 0});
      }
    });
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  void _onDisconnected() {
    _keepAliveTimer?.cancel();
    _setState(WsConnectionState.disconnected);
    _channel?.sink.close();
    _channel = null;
    _subscribed = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_host == null) return; // disconnect() was called; don't schedule.
    _reconnectTimer = Timer(_backoff.nextDelay(), () {
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
    _backoff.reset();
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

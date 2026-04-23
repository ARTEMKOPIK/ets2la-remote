import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../services/navigation_ws_service.dart';
import '../services/pages_ws_service.dart';
import '../services/api_service.dart';
import '../services/keep_alive_service.dart';
import '../services/widget_actions.dart';
import 'settings_provider.dart';

/// Localized error codes emitted by [ConnectionProvider]. UI code maps these
/// to translated strings so error messages respect the user's language.
enum ConnectionErrorCode { unreachable, failed, invalidHost }

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider() : super() {
    // Ports will be set in connect() using AppSettings
    _ready = _loadRecentHosts();
    _wsStateSub = wsService.stateStream.listen((_) {
      if (!_disposed) notifyListeners();
    });
    // Route home-screen widget taps into the live Pages WS. If no session
    // is connected we silently drop the action; the widget still works as
    // a launch-the-app shortcut since MainActivity was started by the tap.
    WidgetActionBridge.instance.setHandler(_handleWidgetAction);
  }

  Future<void> _handleWidgetAction(String action) async {
    if (!isConnected) return;
    switch (action) {
      case WidgetAction.toggleSteering:
        await pagesService.toggleSteering();
        break;
      case WidgetAction.toggleAcc:
        await pagesService.toggleAcc();
        break;
    }
  }

  late final Future<void> _ready;

  /// Resolves once recent hosts have been loaded from disk. Auto-connect
  /// flows should await this to avoid racing against an empty list.
  Future<void> get ready => _ready;

  StreamSubscription<WsConnectionState>? _wsStateSub;
  bool _disposed = false;

  AppSettings? _savedSettings;

  void configurePorts(AppSettings settings) {
    _savedSettings = settings;
    _applyPorts(settings);
  }

  void _applyPorts(AppSettings? settings) {
    if (settings != null) {
      // Clamp ports to valid range 1-65535
      final apiPort = settings.portApi.clamp(1, 65535);
      final vizPort = settings.portViz.clamp(1, 65535);
      final navPort = settings.portNav.clamp(1, 65535);
      final pagesPort = settings.portPages.clamp(1, 65535);
      apiService.setPort(apiPort);
      apiService.setTimeoutSeconds(settings.connectionTimeout);
      wsService.setPort(vizPort);
      navService.setPort(navPort);
      pagesService.setPort(pagesPort);
    }
  }
  final VisualizationWsService wsService = VisualizationWsService();
  final NavigationWsService navService = NavigationWsService();
  final PagesWsService pagesService = PagesWsService();
  final ApiService apiService = ApiService();

  String _currentHost = '';
  List<String> _recentHosts = [];
  bool _isConnecting = false;
  String? _errorMessage;

  String get currentHost => _currentHost;
  List<String> get recentHosts => _recentHosts;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  bool get isConnected => wsService.state == WsConnectionState.connected;
  bool get isActiveOrConnecting =>
      wsService.state == WsConnectionState.connected ||
      wsService.state == WsConnectionState.connecting ||
      _currentHost.isNotEmpty;

  Future<void> _loadRecentHosts() async {
    final prefs = await SharedPreferences.getInstance();
    _recentHosts = prefs.getStringList('recent_hosts') ?? [];
    notifyListeners();
  }

  Future<void> _saveHost(String host) async {
    if (!_recentHosts.contains(host)) {
      _recentHosts.insert(0, host);
      if (_recentHosts.length > 5) _recentHosts = _recentHosts.sublist(0, 5);
    } else {
      _recentHosts.remove(host);
      _recentHosts.insert(0, host);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_hosts', _recentHosts);
  }

  Future<void> removeRecentHost(String host) async {
    if (!_recentHosts.contains(host)) return;
    _recentHosts.remove(host);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_hosts', _recentHosts);
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> connect(String host) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Strip port if user accidentally included it (e.g. "192.168.0.46:37522" → "192.168.0.46")
      String cleanHost = host.trim();
      if (cleanHost.contains(':')) {
        cleanHost = cleanHost.split(':').first.trim();
      }
      _currentHost = cleanHost;
      apiService.setHost(cleanHost);
      // Apply ports from settings on each connect
      // Settings passed from connect_screen for simplicity
      final settings = _savedSettings;
      _applyPorts(settings);

      // HTTP ping is used as a fast pre-check, but a failing ping is not
      // fatal on its own: users have reported setups where only the WS
      // ports are reachable (firewall rules per-port, or the API endpoint
      // briefly 404s during backend startup). We still attempt the real
      // visualization WS handshake and treat *that* as the source of truth.
      final reachable = await apiService.ping();

      await wsService.connect(cleanHost);
      if (wsService.state != WsConnectionState.connected) {
        _errorMessage = reachable
            ? ConnectionErrorCode.failed.name
            : ConnectionErrorCode.unreachable.name;
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      await navService.connect(cleanHost);
      await pagesService.connect(cleanHost);
      await _saveHost(cleanHost);
      // Promote the process so Android doesn't kill the WebSocket when the
      // screen turns off; no-op on non-Android platforms.
      unawaited(KeepAliveService.instance.start(cleanHost));

      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ConnectionProvider.connect error: $e');
      _errorMessage = ConnectionErrorCode.failed.name;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    wsService.disconnect();
    navService.disconnect();
    pagesService.disconnect();
    unawaited(KeepAliveService.instance.stop());
    _currentHost = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _wsStateSub?.cancel();
    wsService.dispose();
    navService.dispose();
    pagesService.dispose();
    super.dispose();
  }
}

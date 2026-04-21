import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../services/navigation_ws_service.dart';
import '../services/pages_ws_service.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider() : super() {
    // Ports will be set in connect() using AppSettings
    _loadRecentHosts();
    wsService.stateStream.listen((_) => notifyListeners());
  }

  AppSettings? _savedSettings;

  void configurePorts(AppSettings settings) {
    _savedSettings = settings;
    _applyPorts(settings);
  }

  void _applyPorts(AppSettings? settings) {
    if (settings != null) {
      apiService.setPort(settings.portApi);
      wsService.setPort(settings.portViz);
      navService.setPort(settings.portNav);
      pagesService.setPort(settings.portPages);
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

      final reachable = await apiService.ping();
      if (!reachable) {
        _errorMessage = 'Cannot reach $host:37520\nMake sure ETS2LA is running';
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      await wsService.connect(cleanHost);
      await navService.connect(cleanHost);
      // Note: portPages from settings not wired here yet — uses default 37523
      await pagesService.connect(cleanHost);
      await _saveHost(cleanHost);

      _isConnecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void disconnect() {
    wsService.disconnect();
    navService.disconnect();
    pagesService.disconnect();
    _currentHost = '';
    notifyListeners();
  }

  @override
  void dispose() {
    wsService.dispose();
    navService.dispose();
    pagesService.dispose();
    super.dispose();
  }
}

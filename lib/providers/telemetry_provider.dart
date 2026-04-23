import 'dart:async';
import 'package:flutter/material.dart';
import '../models/truck_state.dart';
import '../models/plugin_state.dart';
import '../models/telemetry.dart';
// NOTE: TruckTransform used to live here and was parsed from channel 1. The
// mobile UI never renders the truck mesh, so we stopped subscribing to that
// channel in VisualizationWsService and removed the field.
import '../services/websocket_service.dart';
import '../services/navigation_ws_service.dart';
import '../services/api_service.dart';

class TelemetryProvider extends ChangeNotifier {
  TruckState truckState = const TruckState();
  AutopilotStatus autopilotStatus = const AutopilotStatus();
  NavPosition? navPosition;
  NavRoute? navRoute;
  List<PluginInfo> plugins = <PluginInfo>[];

  /// True while a connection was established at least once in this session.
  /// Used to guard background plugin-refresh callbacks from clobbering the
  /// live list after the user manually disconnects.
  bool _hasActiveSession = false;
  bool get hasActiveSession => _hasActiveSession;

  /// Rolling ring buffer of the last ~60s of km/h samples for the sparkline
  /// on the dashboard. Capped so we never grow unboundedly.
  static const int _historyCap = 120;
  static const Duration _sampleInterval = Duration(milliseconds: 500);
  final List<double> _speedHistory = <double>[];
  DateTime _lastSpeedSample = DateTime.fromMillisecondsSinceEpoch(0);

  /// Immutable view of the speed history (oldest first, newest last).
  List<double> get speedHistory => List.unmodifiable(_speedHistory);

  StreamSubscription? _wsSub;
  StreamSubscription? _posSub;
  StreamSubscription? _routeSub;
  Timer? _pluginRefreshTimer;
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Wire the provider to live WS/REST services. Idempotent: re-calling
  /// this swaps the subscriptions without tearing down the provider state,
  /// so telemetry keeps flowing across reconnects.
  void init(
    VisualizationWsService wsService,
    NavigationWsService navService,
    ApiService apiService,
  ) {
    _hasActiveSession = true;
    _wsSub?.cancel();
    _wsSub = wsService.dataStream.listen(_handleWsMessage);

    _posSub?.cancel();
    _posSub = navService.positionStream.listen((pos) {
      navPosition = pos;
      _safeNotify();
    });

    _routeSub?.cancel();
    _routeSub = navService.routeStream.listen((route) {
      navRoute = route;
      _safeNotify();
    });
  }

  void _handleWsMessage(Map<String, dynamic> msg) {
    final channel = msg['channel'] as int?;
    final result = msg['result'] as Map<String, dynamic>?;
    if (result == null) return;
    final data = result['data'];
    if (data == null || data is! Map<String, dynamic>) return;

    switch (channel) {
      case 3:
        truckState = TruckState.fromJson(data);
        _recordSpeedSample();
        _safeNotify();
        break;
      case 7:
        autopilotStatus = AutopilotStatus.fromJson(data);
        _safeNotify();
        break;
    }
  }

  /// Subsample the WS stream at ~2 Hz so 60s of history fits in ~120 points
  /// regardless of backend tick rate.
  void _recordSpeedSample() {
    final now = DateTime.now();
    if (now.difference(_lastSpeedSample) < _sampleInterval) return;
    _lastSpeedSample = now;
    _speedHistory.add(truckState.speedKmh);
    if (_speedHistory.length > _historyCap) {
      _speedHistory.removeRange(0, _speedHistory.length - _historyCap);
    }
  }

  /// Replace the known plugin list. Always publishes the new list — even an
  /// empty one — because the caller has already decided that the response
  /// was authoritative. Use [tryUpdatePluginsFromBackend] for the common
  /// "poll and only commit when the backend actually answered" flow.
  void updatePlugins(List<PluginInfo> list) {
    plugins = List.unmodifiable(list);
    _safeNotify();
  }

  /// Commit [list] as the current plugin state only if it represents a real
  /// backend response (non-empty) OR we already had plugins cached and the
  /// empty result is trustworthy (caller says [authoritative] is `true`).
  /// This prevents a transient network hiccup from collapsing the UI to
  /// "no plugins" for five seconds until the next poll.
  void tryUpdatePluginsFromBackend(
    List<PluginInfo> list, {
    bool authoritative = false,
  }) {
    if (list.isEmpty && !authoritative && plugins.isNotEmpty) return;
    plugins = List.unmodifiable(list);
    _safeNotify();
  }

  void reset() {
    truckState = const TruckState();
    autopilotStatus = const AutopilotStatus();
    navPosition = null;
    navRoute = null;
    plugins = const <PluginInfo>[];
    _speedHistory.clear();
    _lastSpeedSample = DateTime.fromMillisecondsSinceEpoch(0);
    _hasActiveSession = false;
    _wsSub?.cancel();
    _wsSub = null;
    _posSub?.cancel();
    _posSub = null;
    _routeSub?.cancel();
    _routeSub = null;
    _pluginRefreshTimer?.cancel();
    _pluginRefreshTimer = null;
    _safeNotify();
  }

  void startPluginRefresh(
    VisualizationWsService wsService,
    NavigationWsService navService,
    ApiService apiService,
  ) {
    // Cancel existing timer first
    _pluginRefreshTimer?.cancel();

    // Only start if connected
    if (wsService.state != WsConnectionState.connected) return;

    _pluginRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_disposed) return;
      // Check connection before fetching — and bail out if the user
      // disconnected while we were waiting for the poll tick.
      if (wsService.state != WsConnectionState.connected ||
          !_hasActiveSession) {
        _pluginRefreshTimer?.cancel();
        _pluginRefreshTimer = null;
        return;
      }
      final list = await apiService.getPlugins();
      if (_disposed || !_hasActiveSession) return;
      tryUpdatePluginsFromBackend(list);
    });

    // Initial fetch
    apiService.getPlugins().then((list) {
      if (_disposed || !_hasActiveSession) return;
      tryUpdatePluginsFromBackend(list);
    });
  }

  void stopPluginRefresh() {
    _pluginRefreshTimer?.cancel();
    _pluginRefreshTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _wsSub?.cancel();
    _posSub?.cancel();
    _routeSub?.cancel();
    _pluginRefreshTimer?.cancel();
    super.dispose();
  }
}

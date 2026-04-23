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
  List<PluginInfo> plugins = [];

  StreamSubscription? _wsSub;
  StreamSubscription? _posSub;
  StreamSubscription? _routeSub;
  Timer? _pluginRefreshTimer;
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void init(
    VisualizationWsService wsService,
    NavigationWsService navService,
    ApiService apiService,
  ) {
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
        _safeNotify();
        break;
      case 7:
        autopilotStatus = AutopilotStatus.fromJson(data);
        _safeNotify();
        break;
    }
  }

  void updatePlugins(List<PluginInfo> list) {
    plugins = list;
    _safeNotify();
  }

  void reset() {
    truckState = const TruckState();
    autopilotStatus = const AutopilotStatus();
    navPosition = null;
    navRoute = null;
    plugins = [];
    _wsSub?.cancel();
    _posSub?.cancel();
    _routeSub?.cancel();
    _pluginRefreshTimer?.cancel();
    _safeNotify();
  }

  void startPluginRefresh(VisualizationWsService wsService, NavigationWsService navService, ApiService apiService) {
    // Cancel existing timer first
    _pluginRefreshTimer?.cancel();

    // Only start if connected
    if (wsService.state == WsConnectionState.connected) {
      _pluginRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (_disposed) return;
        // Check connection before fetching
        if (wsService.state == WsConnectionState.connected) {
          final list = await apiService.getPlugins();
          if (_disposed) return;
          if (list.isNotEmpty) {
            plugins = list;
            _safeNotify();
          }
        } else {
          // Stop timer when disconnected
          _pluginRefreshTimer?.cancel();
          _pluginRefreshTimer = null;
        }
      });

      // Initial fetch
      apiService.getPlugins().then((list) {
        if (_disposed) return;
        if (list.isNotEmpty) {
          plugins = list;
          _safeNotify();
        }
      });
    }
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

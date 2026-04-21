import 'dart:async';
import 'package:flutter/material.dart';
import '../models/truck_state.dart';
import '../models/plugin_state.dart';
import '../models/telemetry.dart';
import '../services/websocket_service.dart';
import '../services/navigation_ws_service.dart';
import '../services/api_service.dart';

class TelemetryProvider extends ChangeNotifier {
  TruckState truckState = const TruckState();
  TruckTransform truckTransform = const TruckTransform();
  AutopilotStatus autopilotStatus = const AutopilotStatus();
  NavPosition? navPosition;
  NavRoute? navRoute;
  List<PluginInfo> plugins = [];

  StreamSubscription? _wsSub;
  StreamSubscription? _posSub;
  StreamSubscription? _routeSub;
  Timer? _pluginRefreshTimer;

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
      notifyListeners();
    });

    _routeSub?.cancel();
    _routeSub = navService.routeStream.listen((route) {
      navRoute = route;
      notifyListeners();
    });

    _pluginRefreshTimer?.cancel();
    _pluginRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final list = await apiService.getPlugins();
      if (list.isNotEmpty) {
        plugins = list;
        notifyListeners();
      }
    });

    apiService.getPlugins().then((list) {
      if (list.isNotEmpty) {
        plugins = list;
        notifyListeners();
      }
    });
  }

  void _handleWsMessage(Map<String, dynamic> msg) {
    final channel = msg['channel'] as int?;
    final result = msg['result'] as Map<String, dynamic>?;
    if (result == null) return;
    final data = result['data'];
    if (data == null || data is! Map<String, dynamic>) return;

    switch (channel) {
      case 1:
        truckTransform = TruckTransform.fromJson(data);
        break;
      case 3:
        truckState = TruckState.fromJson(data);
        notifyListeners();
        break;
      case 7:
        autopilotStatus = AutopilotStatus.fromJson(data);
        notifyListeners();
        break;
    }
  }

  void updatePlugins(List<PluginInfo> list) {
    plugins = list;
    notifyListeners();
  }

  void reset() {
    truckState = const TruckState();
    truckTransform = const TruckTransform();
    autopilotStatus = const AutopilotStatus();
    navPosition = null;
    navRoute = null;
    plugins = [];
    _wsSub?.cancel();
    _posSub?.cancel();
    _routeSub?.cancel();
    _pluginRefreshTimer?.cancel();
    notifyListeners();
  }

  void startPluginRefresh(VisualizationWsService wsService, NavigationWsService navService, ApiService apiService) {
    // Cancel existing timer first
    _pluginRefreshTimer?.cancel();
    
    // Only start if connected
    if (wsService.state == WsConnectionState.connected) {
      _pluginRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        // Check connection before fetching
        if (wsService.state == WsConnectionState.connected) {
          final list = await apiService.getPlugins();
          if (list.isNotEmpty) {
            plugins = list;
            notifyListeners();
          }
        } else {
          // Stop timer when disconnected
          _pluginRefreshTimer?.cancel();
          _pluginRefreshTimer = null;
        }
      });

      // Initial fetch
      apiService.getPlugins().then((list) {
        if (list.isNotEmpty) {
          plugins = list;
          notifyListeners();
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
    _wsSub?.cancel();
    _posSub?.cancel();
    _routeSub?.cancel();
    _pluginRefreshTimer?.cancel();
    super.dispose();
  }
}

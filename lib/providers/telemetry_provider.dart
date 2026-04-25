import 'dart:async';
import 'package:flutter/material.dart';
import '../models/truck_state.dart';
import '../models/plugin_state.dart';
import '../models/telemetry.dart';
import '../models/telemetry_event.dart';
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
  static const int historyCap = 120;
  static const Duration _sampleInterval = Duration(milliseconds: 500);
  final List<double> _speedHistory = <double>[];
  DateTime _lastSpeedSample = DateTime.fromMillisecondsSinceEpoch(0);

  /// Immutable view of the speed history (oldest first, newest last).
  List<double> get speedHistory => List.unmodifiable(_speedHistory);

  StreamSubscription? _wsSub;
  StreamSubscription? _posSub;
  StreamSubscription? _routeSub;
  Timer? _pluginRefreshTimer;
  bool _pluginRefreshBusy = false;
  bool _disposed = false;

  /// Broadcast stream of one-shot telemetry transitions (autopilot on/off,
  /// ACC on/off, crossing the speed limit). Consumers — the haptic
  /// engine and TTS announcer — subscribe to this instead of diffing
  /// the raw state themselves.
  final StreamController<TelemetryEvent> _events =
      StreamController<TelemetryEvent>.broadcast();
  Stream<TelemetryEvent> get events => _events.stream;

  void _emit(TelemetryEventKind kind, {double? speed, double? limit}) {
    if (_disposed || _events.isClosed) return;
    _events.add(TelemetryEvent(
      kind,
      at: DateTime.now(),
      speedKmh: speed,
      speedLimitKmh: limit,
    ));
  }

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
        final prev = truckState;
        truckState = TruckState.fromJson(data);
        _recordSpeedSample();
        _detectSpeedLimitEvent(prev, truckState);
        _safeNotify();
        break;
      case 7:
        final prev = autopilotStatus;
        autopilotStatus = AutopilotStatus.fromJson(data);
        _detectAutopilotEvents(prev, autopilotStatus);
        _safeNotify();
        break;
    }
  }

  void _detectAutopilotEvents(AutopilotStatus prev, AutopilotStatus curr) {
    if (!prev.steeringEnabled && curr.steeringEnabled) {
      _emit(TelemetryEventKind.steeringEnabled);
    } else if (prev.steeringEnabled && !curr.steeringEnabled) {
      _emit(TelemetryEventKind.steeringDisabled);
    }
    if (!prev.accEnabled && curr.accEnabled) {
      _emit(TelemetryEventKind.accEnabled);
    } else if (prev.accEnabled && !curr.accEnabled) {
      _emit(TelemetryEventKind.accDisabled);
    }
    if (!prev.collisionEnabled && curr.collisionEnabled) {
      _emit(TelemetryEventKind.collisionEnabled);
    } else if (prev.collisionEnabled && !curr.collisionEnabled) {
      _emit(TelemetryEventKind.collisionDisabled);
    }
  }

  /// Emit one event when the truck crosses the speed limit and one more
  /// when it drops back — no continuous spam while staying above it.
  void _detectSpeedLimitEvent(TruckState prev, TruckState curr) {
    if (curr.speedLimit <= 0) return;
    if (!prev.isOverSpeedLimit && curr.isOverSpeedLimit) {
      _emit(
        TelemetryEventKind.overSpeedLimit,
        speed: curr.speedKmh,
        limit: curr.speedLimitKmh,
      );
    } else if (prev.isOverSpeedLimit && !curr.isOverSpeedLimit) {
      _emit(
        TelemetryEventKind.backUnderSpeedLimit,
        speed: curr.speedKmh,
        limit: curr.speedLimitKmh,
      );
    }
  }

  /// Subsample the WS stream at ~2 Hz so 60s of history fits in ~120 points
  /// regardless of backend tick rate.
  void _recordSpeedSample() {
    final now = DateTime.now();
    if (now.difference(_lastSpeedSample) < _sampleInterval) return;
    _lastSpeedSample = now;
    _speedHistory.add(truckState.speedKmh);
    if (_speedHistory.length > historyCap) {
      _speedHistory.removeRange(0, _speedHistory.length - historyCap);
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
    _pluginRefreshBusy = false;
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

    _pluginRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Guard: prevent overlapping API calls (e.g. if previous call took >5s)
      if (_pluginRefreshBusy) return;
      _pluginRefreshBusy = true;
      try {
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
      } finally {
        _pluginRefreshBusy = false;
      }
    });

    // Initial fetch
    apiService.getPlugins().then((list) {
      if (_disposed || !_hasActiveSession) return;
      tryUpdatePluginsFromBackend(list);
    }).catchError((e, st) {
      debugPrint('TelemetryProvider initial plugin fetch failed: $e\n$st');
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
    _events.close();
    super.dispose();
  }
}

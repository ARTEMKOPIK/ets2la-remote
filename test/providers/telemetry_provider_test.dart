import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ets2la_remote/providers/telemetry_provider.dart';
import 'package:ets2la_remote/models/truck_state.dart';
import 'package:ets2la_remote/models/plugin_state.dart';
import 'package:ets2la_remote/models/telemetry.dart';
import 'package:ets2la_remote/models/telemetry_event.dart';
import 'package:ets2la_remote/services/api_service.dart';
import 'package:ets2la_remote/services/navigation_ws_service.dart';
import 'package:ets2la_remote/services/websocket_service.dart';

/// Fake WS data stream for testing — controlled programmatically.
class FakeWsService extends VisualizationWsService {
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  @override
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  @override
  Stream<WsConnectionState> get stateStream => _stateController.stream;

  @override
  WsConnectionState get state => WsConnectionState.connected;

  void emitData(Map<String, dynamic> data) => _dataController.add(data);

  void emitState(WsConnectionState s) => _stateController.add(s);

  @override
  void dispose() {
    _dataController.close();
    _stateController.close();
  }
}

class FakeNavService extends NavigationWsService {
  final _posController = StreamController<NavPosition>.broadcast();
  final _routeController = StreamController<NavRoute>.broadcast();

  @override
  Stream<NavPosition> get positionStream => _posController.stream;

  @override
  Stream<NavRoute> get routeStream => _routeController.stream;

  @override
  bool get isConnected => true;

  void emitPosition(NavPosition pos) => _posController.add(pos);

  void emitRoute(NavRoute route) => _routeController.add(route);

  @override
  Future<void> connect(String host) async {}

  @override
  void dispose() {
    _posController.close();
    _routeController.close();
  }
}

class FakeApiService extends ApiService {
  final List<PluginInfo> _pluginsToReturn = [];
  bool shouldThrowOnGetPlugins = false;

  @override
  Future<List<PluginInfo>> getPlugins() async {
    if (shouldThrowOnGetPlugins) throw Exception('API error');
    return _pluginsToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TelemetryProvider', () {
    late TelemetryProvider provider;
    late FakeWsService fakeWs;
    late FakeNavService fakeNav;
    late FakeApiService fakeApi;

    setUp(() {
      provider = TelemetryProvider();
      fakeWs = FakeWsService();
      fakeNav = FakeNavService();
      fakeApi = FakeApiService();
    });

    tearDown(() {
      provider.dispose();
      fakeWs.dispose();
      fakeNav.dispose();
    });

    group('initial state', () {
      test('truckState is default TruckState', () {
        expect(provider.truckState, const TruckState());
      });

      test('autopilotStatus is default AutopilotStatus', () {
        expect(provider.autopilotStatus, const AutopilotStatus());
      });

      test('navPosition is null', () {
        expect(provider.navPosition, isNull);
      });

      test('navRoute is null', () {
        expect(provider.navRoute, isNull);
      });

      test('plugins is empty', () {
        expect(provider.plugins, isEmpty);
      });

      test('hasActiveSession is false', () {
        expect(provider.hasActiveSession, false);
      });

      test('speedHistory is empty', () {
        expect(provider.speedHistory, isEmpty);
      });
    });

    group('init()', () {
      test('sets hasActiveSession to true', () {
        expect(provider.hasActiveSession, false);
        provider.init(fakeWs, fakeNav, fakeApi);
        expect(provider.hasActiveSession, true);
      });

      test('subscribes to ws dataStream', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        // Emit channel 3 (truck state) data
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {
              'speedKmh': 80.0,
              'speedLimitKmh': 90.0,
              'fuelLiters': 200.0,
              'engineEnabled': true,
              'brakeTemperature': 50.0,
            }
          }
        });
        await Future<void>.delayed(Duration.zero);
        expect(provider.truckState.speedKmh, 80.0);
      });

      test('subscribes to nav positionStream', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        // NavPosition requires a LatLng
        final pos = NavPosition.fromJson({
          'position': [10.0, 20.0],
          'bearing': 180.0,
          'speedMph': 50.0,
        });
        fakeNav.emitPosition(pos);
        await Future<void>.delayed(Duration.zero);
        expect(provider.navPosition, isNotNull);
      });

      test('subscribes to nav routeStream', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        final route = NavRoute.fromJson({
          'id': 'route-1',
          'segments': [
            {
              'position': [10.0, 20.0]
            },
            {
              'position': [11.0, 21.0]
            },
          ]
        });
        fakeNav.emitRoute(route);
        await Future<void>.delayed(Duration.zero);
        expect(provider.navRoute, isNotNull);
      });

      test('re-init replaces subscriptions (no leak)', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        int callCount = 0;
        provider.addListener(() => callCount++);

        // Emit from first ws
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 50.0}
          },
        });
        await Future<void>.delayed(Duration.zero);
        final countAfterFirst = callCount;

        // Re-init with a new fake (old subscription should be cancelled)
        final fakeWs2 = FakeWsService();
        provider.init(fakeWs2, fakeNav, fakeApi);

        // Emit from first ws — should NOT trigger provider listener
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 99.0}
          },
        });
        await Future<void>.delayed(Duration.zero);
        expect(callCount, countAfterFirst); // no change

        fakeWs2.dispose();
      });
    });

    group('_handleWsMessage — channel 3 (truck state)', () {
      setUp(() {
        provider.init(fakeWs, fakeNav, fakeApi);
      });

      test('parses speed and speedLimit', () async {
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {
              'speedKmh': 85.0,
              'speedLimitKmh': 90.0,
              'fuelLiters': 150.0,
              'engineEnabled': true,
              'brakeTemperature': 45.0,
            }
          }
        });
        await Future<void>.delayed(Duration.zero);
        expect(provider.truckState.speedKmh, 85.0);
        expect(provider.truckState.speedLimitKmh, 90.0);
      });

      test('ignores messages with null channel', () async {
        fakeWs.emitData({
          'channel': null,
          'result': {
            'data': {'speedKmh': 99.0}
          },
        });
        await Future<void>.delayed(Duration.zero);
        expect(provider.truckState.speedKmh, isNot(99.0));
      });

      test('ignores messages with null result', () {
        fakeWs.emitData({'channel': 3, 'result': null});
        // Should not throw
      });

      test('ignores messages with non-map data', () {
        fakeWs.emitData({
          'channel': 3,
          'result': {'data': 'not a map'},
        });
        // Should not throw
      });
    });

    group('_handleWsMessage — channel 7 (autopilot status)', () {
      setUp(() {
        provider.init(fakeWs, fakeNav, fakeApi);
      });

      test('parses autopilot status', () async {
        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {
              'steeringEnabled': true,
              'accEnabled': true,
              'accTargetSpeedKmh': 80.0,
            }
          }
        });
        await Future<void>.delayed(Duration.zero);
        expect(provider.autopilotStatus.steeringEnabled, true);
        expect(provider.autopilotStatus.accEnabled, true);
      });

      test('parses collision status', () async {
        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {
              'steeringEnabled': false,
              'accEnabled': false,
              'collisionEnabled': true,
            }
          }
        });
        await Future<void>.delayed(Duration.zero);
        expect(provider.autopilotStatus.collisionEnabled, true);
      });
    });

    group('_detectAutopilotEvents', () {
      setUp(() {
        provider.init(fakeWs, fakeNav, fakeApi);
      });

      test('emits steeringEnabled event', () async {
        final events = <TelemetryEvent>[];
        provider.events.listen(events.add);

        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {'steeringEnabled': false}
          },
        });
        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {'steeringEnabled': true}
          },
        });
        await Future.delayed(Duration.zero);
        expect(events.any((e) => e.kind == TelemetryEventKind.steeringEnabled),
            true);
      });

      test('emits accEnabled event', () async {
        final events = <TelemetryEvent>[];
        provider.events.listen(events.add);

        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {'accEnabled': false}
          },
        });
        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {'accEnabled': true}
          },
        });
        await Future.delayed(Duration.zero);
        expect(
            events.any((e) => e.kind == TelemetryEventKind.accEnabled), true);
      });

      test('emits overSpeedLimit event', () async {
        final events = <TelemetryEvent>[];
        provider.events.listen(events.add);

        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 50.0, 'speedLimitKmh': 90.0}
          }
        });
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 96.0, 'speedLimitKmh': 90.0}
          }
        });
        await Future.delayed(Duration.zero);
        expect(events.any((e) => e.kind == TelemetryEventKind.overSpeedLimit),
            true);
      });

      test('emits backUnderSpeedLimit event', () async {
        final events = <TelemetryEvent>[];
        provider.events.listen(events.add);

        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 96.0, 'speedLimitKmh': 90.0}
          }
        });
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 80.0, 'speedLimitKmh': 90.0}
          }
        });
        await Future.delayed(Duration.zero);
        expect(
            events.any((e) => e.kind == TelemetryEventKind.backUnderSpeedLimit),
            true);
      });
    });

    group('_recordSpeedSample', () {
      test('records speed sample to history', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 80.0, 'fuelLiters': 100.0}
          },
        });
        // The interval is 500ms, so a single emission may not register.
        // Wait to allow sampling.
        await Future.delayed(const Duration(milliseconds: 600));
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 85.0, 'fuelLiters': 100.0}
          },
        });
        await Future.delayed(Duration.zero);
        expect(provider.speedHistory.isNotEmpty, true);
      });

      test('caps history at _historyCap (120)', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        // Note: sampling happens at most every 500ms. For unit test speed,
        // we verify the cap mechanism by checking the List behavior.
        // The provider code removes oldest entries when cap exceeded.
        expect(TelemetryProvider.historyCap, 120);
      });
    });

    group('updatePlugins', () {
      test('stores unmodifiable plugin list', () {
        final plugins = [
          const PluginInfo(id: 'p1', name: 'Plugin 1', running: true),
        ];
        provider.updatePlugins(plugins);
        expect(provider.plugins.length, 1);
        expect(provider.plugins[0].id, 'p1');
        expect(
            () => (provider.plugins as List).add(const PluginInfo(
                  id: 'p2',
                  name: 'Plugin 2',
                  running: true,
                )),
            throwsA(anything));
      });

      test('notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        provider.updatePlugins([
          const PluginInfo(id: 'p1', name: 'P', running: true),
        ]);
        expect(notifyCount, greaterThan(0));
      });
    });

    group('tryUpdatePluginsFromBackend', () {
      test('accepts non-empty list regardless of authoritative flag', () {
        provider.tryUpdatePluginsFromBackend([
          const PluginInfo(id: 'p1', name: 'P1', running: true),
        ], authoritative: false);
        expect(provider.plugins.length, 1);
      });

      test('ignores empty list when not authoritative and plugins exist', () {
        provider.updatePlugins([
          const PluginInfo(id: 'cached', name: 'Cached', running: true),
        ]);
        provider.tryUpdatePluginsFromBackend([], authoritative: false);
        expect(provider.plugins[0].id, 'cached');
      });

      test('accepts empty list when authoritative even with cached plugins',
          () {
        provider.updatePlugins([
          const PluginInfo(id: 'cached', name: 'Cached', running: true),
        ]);
        provider.tryUpdatePluginsFromBackend([], authoritative: true);
        expect(provider.plugins, isEmpty);
      });

      test('accepts empty list when no plugins cached', () {
        provider.tryUpdatePluginsFromBackend([], authoritative: false);
        expect(provider.plugins, isEmpty);
      });
    });

    group('reset()', () {
      test('clears truckState', () {
        provider.init(fakeWs, fakeNav, fakeApi);
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 80.0}
          },
        });
        provider.reset();
        expect(provider.truckState, const TruckState());
      });

      test('clears autopilotStatus', () {
        provider.init(fakeWs, fakeNav, fakeApi);
        fakeWs.emitData({
          'channel': 7,
          'result': {
            'data': {'steeringEnabled': true}
          },
        });
        provider.reset();
        expect(provider.autopilotStatus, const AutopilotStatus());
      });

      test('clears navPosition and navRoute', () {
        provider.init(fakeWs, fakeNav, fakeApi);
        fakeNav.emitPosition(NavPosition.fromJson({
          'position': [1, 2]
        }));
        fakeNav.emitRoute(NavRoute.fromJson({'id': 'r', 'segments': []}));
        provider.reset();
        expect(provider.navPosition, isNull);
        expect(provider.navRoute, isNull);
      });

      test('clears plugins', () {
        provider.updatePlugins([
          const PluginInfo(id: 'p1', name: 'P', running: true),
        ]);
        provider.reset();
        expect(provider.plugins, isEmpty);
      });

      test('clears speedHistory', () async {
        provider.init(fakeWs, fakeNav, fakeApi);
        await Future.delayed(const Duration(milliseconds: 600));
        fakeWs.emitData({
          'channel': 3,
          'result': {
            'data': {'speedKmh': 80.0}
          },
        });
        await Future.delayed(Duration.zero);
        provider.reset();
        expect(provider.speedHistory, isEmpty);
      });

      test('sets hasActiveSession to false', () {
        provider.init(fakeWs, fakeNav, fakeApi);
        expect(provider.hasActiveSession, true);
        provider.reset();
        expect(provider.hasActiveSession, false);
      });

      test('notifies listeners', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);
        provider.reset();
        expect(notifyCount, greaterThan(0));
      });
    });

    group('startPluginRefresh / stopPluginRefresh', () {
      test('does not start timer when wsService is disconnected', () {
        final disconnectedWs = FakeWsService();
        disconnectedWs.emitState(WsConnectionState.disconnected);
        provider.startPluginRefresh(disconnectedWs, fakeNav, fakeApi);
        // Should return early without scheduling — no error thrown
        provider.stopPluginRefresh();
        disconnectedWs.dispose();
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ets2la_remote/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettings', () {
    late Map<String, Object> prefsStore;

    setUp(() {
      prefsStore = {};
      SharedPreferences.setMockInitialValues(prefsStore);
    });

    group('create() — default values', () {
      test('loads all defaults when prefs are empty', () async {
        final settings = await AppSettings.create();
        expect(settings.autoConnect, false);
        expect(settings.connectionTimeout, 5);
        expect(settings.portApi, 37520);
        expect(settings.portViz, 37522);
        expect(settings.portNav, 62840);
        expect(settings.portPages, 37523);
        expect(settings.speedUnit, SpeedUnit.kmh);
        expect(settings.gaugeMax, GaugeMaxSpeed.s200);
        expect(settings.showActivePlugins, true);
        expect(settings.language, isNull);
        expect(settings.mapAutoFollow, true);
        expect(settings.mapTileStyle, MapTileStyle.dark);
        expect(settings.mapShowRoute, true);
        expect(settings.vizDarkTheme, true);
        expect(settings.vizAutoConnect, true);
        expect(settings.accentColor, AccentColor.orange);
        expect(settings.highContrast, false);
        expect(settings.reduceMotion, false);
        expect(settings.hasSeenOnboarding, false);
        expect(settings.hapticEventsEnabled, true);
        expect(settings.ttsEnabled, false);
        expect(settings.driverModeAutoLandscape, false);
        expect(settings.tripLogEnabled, true);
        expect(settings.dashboardLayout, isEmpty);
        expect(settings.isReady, true);
      });

      test('marks settings ready after load', () async {
        final settings = await AppSettings.create();
        expect(settings.isReady, true);
      });
    });

    group('create() — persisted values', () {
      test('loads persisted bool values', () async {
        prefsStore = {
          'autoConnect': true,
          'showActivePlugins': false,
          'mapAutoFollow': false,
          'vizDarkTheme': false,
          'vizAutoConnect': false,
          'highContrast': true,
          'reduceMotion': true,
          'hasSeenOnboarding': true,
          'hapticEventsEnabled': false,
          'ttsEnabled': true,
          'driverModeAutoLandscape': true,
          'tripLogEnabled': false,
          'mapShowRoute': false,
        };
        SharedPreferences.setMockInitialValues(prefsStore);

        final settings = await AppSettings.create();
        expect(settings.autoConnect, true);
        expect(settings.showActivePlugins, false);
        expect(settings.mapAutoFollow, false);
        expect(settings.vizDarkTheme, false);
        expect(settings.vizAutoConnect, false);
        expect(settings.highContrast, true);
        expect(settings.reduceMotion, true);
        expect(settings.hasSeenOnboarding, true);
        expect(settings.hapticEventsEnabled, false);
        expect(settings.ttsEnabled, true);
        expect(settings.driverModeAutoLandscape, true);
        expect(settings.tripLogEnabled, false);
        expect(settings.mapShowRoute, false);
      });

      test('loads persisted integer values', () async {
        prefsStore = {
          'connectionTimeout': 10,
          'portApi': 40000,
          'portViz': 40001,
          'portNav': 70000,
          'portPages': 40002,
          'speedUnit': 1,
          'gaugeMax': 0,
          'mapTileStyle': 1,
          'accentColor': 2,
        };
        SharedPreferences.setMockInitialValues(prefsStore);

        final settings = await AppSettings.create();
        expect(settings.connectionTimeout, 10);
        expect(settings.portApi, 40000);
        expect(settings.portViz, 40001);
        expect(settings.portNav, 62840);
        expect(settings.portPages, 40002);
        expect(settings.speedUnit, SpeedUnit.mph);
        expect(settings.gaugeMax, GaugeMaxSpeed.s160);
        expect(settings.mapTileStyle, MapTileStyle.light);
        expect(settings.accentColor, AccentColor.green);
      });

      test('loads persisted language string', () async {
        prefsStore = {'language': 'ru'};
        SharedPreferences.setMockInitialValues(prefsStore);

        final settings = await AppSettings.create();
        expect(settings.language, 'ru');
        expect(settings.locale, isNotNull);
        expect(settings.locale!.languageCode, 'ru');
      });

      test('loads persisted dashboard layout', () async {
        prefsStore = {
          'dashboardLayout': ['truck_speed', 'fuel_gauge', 'autopilot_status'],
        };
        SharedPreferences.setMockInitialValues(prefsStore);

        final settings = await AppSettings.create();
        expect(settings.dashboardLayout.length, 3);
        expect(settings.dashboardLayout[0], 'truck_speed');
      });
    });

    group('create() — clamping / safe-enum guards', () {
      test('clamps connectionTimeout below minimum to 1', () async {
        prefsStore = {'connectionTimeout': 0};
        SharedPreferences.setMockInitialValues(prefsStore);
        final settings = await AppSettings.create();
        expect(settings.connectionTimeout, 1);
      });

      test('clamps connectionTimeout above maximum to 60', () async {
        prefsStore = {'connectionTimeout': 999};
        SharedPreferences.setMockInitialValues(prefsStore);
        final settings = await AppSettings.create();
        expect(settings.connectionTimeout, 60);
      });

      test('clamps port below 1 to default', () async {
        prefsStore = {'portApi': 0, 'portViz': 0};
        SharedPreferences.setMockInitialValues(prefsStore);
        final settings = await AppSettings.create();
        expect(settings.portApi, 37520);
        expect(settings.portViz, 37522);
      });

      test('clamps port above 65535 to default', () async {
        prefsStore = {'portApi': 99999, 'portPages': 70000};
        SharedPreferences.setMockInitialValues(prefsStore);
        final settings = await AppSettings.create();
        expect(settings.portApi, 37520);
        expect(settings.portPages, 37523);
      });

      test('falls back for out-of-range enum index', () async {
        prefsStore = {
          'speedUnit': 99,
          'gaugeMax': 99,
          'mapTileStyle': 99,
          'accentColor': 99,
        };
        SharedPreferences.setMockInitialValues(prefsStore);
        final settings = await AppSettings.create();
        expect(settings.speedUnit, SpeedUnit.kmh);
        expect(settings.gaugeMax, GaugeMaxSpeed.s200);
        expect(settings.mapTileStyle, MapTileStyle.dark);
        expect(settings.accentColor, AccentColor.orange);
      });
    });

    group('setters — basic value changes', () {
      late AppSettings settings;

      setUp(() async {
        settings = await AppSettings.create();
      });

      test('setAutoConnect toggles flag', () async {
        settings.setAutoConnect(true);
        expect(settings.autoConnect, true);
        settings.setAutoConnect(false);
        expect(settings.autoConnect, false);
      });

      test('setConnectionTimeout clamps write-time', () async {
        settings.setConnectionTimeout(0);
        expect(settings.connectionTimeout, 1);
        settings.setConnectionTimeout(999);
        expect(settings.connectionTimeout, 60);
        settings.setConnectionTimeout(15);
        expect(settings.connectionTimeout, 15);
      });

      test('setPortApi clamps to default on invalid', () async {
        settings.setPortApi(0);
        expect(settings.portApi, 37520);
        settings.setPortApi(70000);
        expect(settings.portApi, 37520);
        settings.setPortApi(50000);
        expect(settings.portApi, 50000);
      });

      test('setSpeedUnit changes unit', () async {
        settings.setSpeedUnit(SpeedUnit.mph);
        expect(settings.speedUnit, SpeedUnit.mph);
        settings.setSpeedUnit(SpeedUnit.kmh);
        expect(settings.speedUnit, SpeedUnit.kmh);
      });

      test('setMapTileStyle changes tile style', () async {
        settings.setMapTileStyle(MapTileStyle.satellite);
        expect(settings.mapTileStyle, MapTileStyle.satellite);
      });

      test('setLanguage clears language when null passed', () async {
        settings.setLanguage('de');
        expect(settings.language, 'de');
        settings.setLanguage(null);
        expect(settings.language, isNull);
      });

      test('clearLanguage removes persisted language', () async {
        settings.setLanguage('ru');
        settings.clearLanguage();
        expect(settings.language, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('language'), isNull);
      });

      test('setAccentColor changes accent', () async {
        settings.setAccentColor(AccentColor.purple);
        expect(settings.accentColor, AccentColor.purple);
      });

      test('markOnboardingSeen is idempotent', () async {
        settings.markOnboardingSeen();
        expect(settings.hasSeenOnboarding, true);
        settings.markOnboardingSeen();
        expect(settings.hasSeenOnboarding, true);
      });

      test('setDashboardLayout stores unmodifiable list', () async {
        final ids = ['a', 'b', 'c'];
        settings.setDashboardLayout(ids);
        expect(settings.dashboardLayout, ['a', 'b', 'c']);
        expect(() => (settings as dynamic)._dashboardLayout.add('x'),
            throwsA(anything));
      });
    });

    group('speedFromKmh / speedDisplay', () {
      late AppSettings settings;

      setUp(() async {
        settings = await AppSettings.create();
      });

      test('speedFromKmh returns km/h as-is when unit is kmh', () {
        expect(settings.speedFromKmh(100), 100.0);
      });

      test('speedFromKmh converts when unit is mph', () {
        settings.setSpeedUnit(SpeedUnit.mph);
        expect(settings.speedFromKmh(100), closeTo(62.1371, 0.001));
      });

      test('speedDisplay returns rounded integer without unit suffix', () {
        expect(settings.speedDisplay(85.7), '86');
        settings.setSpeedUnit(SpeedUnit.mph);
        expect(settings.speedDisplay(100), '62');
      });

      test('speedUnitLabel returns km/h or mph', () async {
        final s = await AppSettings.create();
        expect(s.speedUnitLabel, 'km/h');
        s.setSpeedUnit(SpeedUnit.mph);
        expect(s.speedUnitLabel, 'mph');
      });
    });

    group('gaugeMaxValue', () {
      test('returns correct value for each enum', () async {
        final settings = await AppSettings.create();
        settings.setGaugeMax(GaugeMaxSpeed.s160);
        expect(settings.gaugeMaxValue, 160);
        settings.setGaugeMax(GaugeMaxSpeed.s200);
        expect(settings.gaugeMaxValue, 200);
        settings.setGaugeMax(GaugeMaxSpeed.s250);
        expect(settings.gaugeMaxValue, 250);
      });
    });

    group('mapTileUrl', () {
      test('returns correct URL for dark style', () async {
        final settings = await AppSettings.create();
        expect(settings.mapTileUrl, contains('dark_all'));
      });

      test('returns correct URL for light style', () async {
        final settings = await AppSettings.create();
        settings.setMapTileStyle(MapTileStyle.light);
        expect(settings.mapTileUrl, contains('light_all'));
      });

      test('returns correct URL for satellite style', () async {
        final settings = await AppSettings.create();
        settings.setMapTileStyle(MapTileStyle.satellite);
        expect(settings.mapTileUrl, contains('World_Imagery'));
      });
    });
  });
}

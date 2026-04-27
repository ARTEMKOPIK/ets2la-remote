import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedUnit { kmh, mph }

enum GaugeMaxSpeed { s160, s200, s250 }

enum MapTileStyle { dark, light, satellite }

/// Accent colour options exposed in Settings. The underlying hex values
/// live in [AppColors.accentFor] so that changing a palette value in one
/// place re-skins the whole app.
enum AccentColor { orange, blue, green, purple }

/// User-facing preference for whether the app should be skinned with a
/// higher-contrast palette (thicker borders, brighter foregrounds). This
/// is independent of the system `highContrast` flag on purpose: the
/// system flag is coarse, and most users who want the extra contrast
/// also want the accent colour preserved.

class AppSettings extends ChangeNotifier {
  // ── Connection ────────────────────────────────────────────────
  bool _autoConnect = false;
  int _connectionTimeout = 5; // seconds
  int _portApi = 37520;
  int _portViz = 37522;
  int _portNav = 62840;
  int _portPages = 37523;

  bool get autoConnect => _autoConnect;
  int get connectionTimeout => _connectionTimeout;
  int get portApi => _portApi;
  int get portViz => _portViz;
  int get portNav => _portNav;
  int get portPages => _portPages;

  // ── Appearance ────────────────────────────────────────────────
  SpeedUnit _speedUnit = SpeedUnit.kmh;
  GaugeMaxSpeed _gaugeMax = GaugeMaxSpeed.s200;
  bool _showActivePlugins = true;

  // Language: null = system default, 'en' = English, 'ru' = Russian
  String? _language;

  String? get language => _language;
  Locale? get locale => _language != null ? Locale(_language!) : null;

  SpeedUnit get speedUnit => _speedUnit;
  GaugeMaxSpeed get gaugeMax => _gaugeMax;
  bool get showActivePlugins => _showActivePlugins;

  double get gaugeMaxValue {
    switch (_gaugeMax) {
      case GaugeMaxSpeed.s160:
        return 160;
      case GaugeMaxSpeed.s200:
        return 200;
      case GaugeMaxSpeed.s250:
        return 250;
    }
  }

  /// 1 km/h converted to the user's preferred unit. Centralises the
  /// `* 0.621371` magic number so widgets never have to know the factor.
  static const double _kmhToMph = 0.621371;

  /// Value-form conversion of a km/h reading into the user's preferred
  /// display unit (mph or km/h). Use this when you need the raw number
  /// — e.g. to drive a gauge animation or compare to `gaugeMaxValue`.
  double speedFromKmh(double kmh) =>
      _speedUnit == SpeedUnit.mph ? kmh * _kmhToMph : kmh;

  /// Text-form version of [speedFromKmh] suitable for direct display.
  /// Returns a whole number (rounded) with no unit suffix.
  String speedDisplay(double kmh) => speedFromKmh(kmh).toStringAsFixed(0);

  String get speedUnitLabel => _speedUnit == SpeedUnit.mph ? 'mph' : 'km/h';

  // ── Map ───────────────────────────────────────────────────────
  bool _mapAutoFollow = true;
  MapTileStyle _mapTileStyle = MapTileStyle.dark;
  bool _mapShowRoute = true;

  bool get mapAutoFollow => _mapAutoFollow;
  MapTileStyle get mapTileStyle => _mapTileStyle;
  bool get mapShowRoute => _mapShowRoute;

  String get mapTileUrl {
    switch (_mapTileStyle) {
      case MapTileStyle.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapTileStyle.light:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case MapTileStyle.satellite:
        // ArcGIS satellite — note: no subdomains, tile order is z/y/x
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.jpg';
    }
  }

  // ── 3D View ───────────────────────────────────────────────────
  bool _vizDarkTheme = true;
  bool _vizAutoConnect = true;

  bool get vizDarkTheme => _vizDarkTheme;
  bool get vizAutoConnect => _vizAutoConnect;

  // ── Appearance / Accessibility ────────────────────────────────
  AccentColor _accentColor = AccentColor.orange;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _hasSeenOnboarding = false;

  AccentColor get accentColor => _accentColor;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // ── Feedback (UX round 3) ─────────────────────────────────────
  bool _hapticEventsEnabled = true;
  bool _ttsEnabled = false;
  bool _driverModeAutoLandscape = false;

  /// Whether distinct vibration patterns should fire for autopilot /
  /// ACC / speed-limit events. Off under reduce-motion regardless of
  /// this flag (the haptic engine checks both).
  bool get hapticEventsEnabled => _hapticEventsEnabled;

  /// Speak short phrases ("Autopilot on", "Over the limit") on telemetry
  /// transitions. Off by default — the user opts in.
  bool get ttsEnabled => _ttsEnabled;

  /// When true, Driver Mode is automatically engaged as soon as the
  /// device rotates into landscape. When false the user has to tap the
  /// dashboard toolbar button to enter it.
  bool get driverModeAutoLandscape => _driverModeAutoLandscape;

  // ── Trip log (UX round 3) ─────────────────────────────────────
  bool _tripLogEnabled = true;

  /// Whether live telemetry should feed the session/trip log. Disable
  /// to stop recording without losing existing history.
  bool get tripLogEnabled => _tripLogEnabled;

  // ── Dashboard layout (UX round 3) ─────────────────────────────
  /// Ordered list of card ids the user has enabled on the main
  /// dashboard. An empty list means "use the default layout". Ids
  /// are defined in `lib/widgets/dashboard_cards.dart`.
  List<String> _dashboardLayout = const <String>[];
  List<String> get dashboardLayout => List.unmodifiable(_dashboardLayout);

  // ─────────────────────────────────────────────────────────────

  bool _isReady = false;
  bool get isReady => _isReady;

  AppSettings._();

  /// Create and load settings from SharedPreferences.
  /// Always use this instead of the constructor.
  static Future<AppSettings> create() async {
    final instance = AppSettings._();
    await instance._load();
    return instance;
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _autoConnect = p.getBool('autoConnect') ?? false;
    // Clamp on load too (not just in the UI that writes the value): protects
    // against corrupted prefs, app downgrades, or prefs edited by hand.
    _connectionTimeout = (p.getInt('connectionTimeout') ?? 5).clamp(1, 60);
    _portApi = _clampPort(p.getInt('portApi'), 37520);
    _portViz = _clampPort(p.getInt('portViz'), 37522);
    _portNav = _clampPort(p.getInt('portNav'), 62840);
    _portPages = _clampPort(p.getInt('portPages'), 37523);
    _speedUnit =
        _safeEnum(SpeedUnit.values, p.getInt('speedUnit'), SpeedUnit.kmh);
    _gaugeMax = _safeEnum(
        GaugeMaxSpeed.values, p.getInt('gaugeMax'), GaugeMaxSpeed.s200);
    _showActivePlugins = p.getBool('showActivePlugins') ?? true;
    _language = p.getString('language'); // null = system default
    _mapAutoFollow = p.getBool('mapAutoFollow') ?? true;
    _mapTileStyle = _safeEnum(
        MapTileStyle.values, p.getInt('mapTileStyle'), MapTileStyle.dark);
    _mapShowRoute = p.getBool('mapShowRoute') ?? true;
    _vizDarkTheme = p.getBool('vizDarkTheme') ?? true;
    _vizAutoConnect = p.getBool('vizAutoConnect') ?? true;
    _accentColor = _safeEnum(
        AccentColor.values, p.getInt('accentColor'), AccentColor.orange);
    _highContrast = p.getBool('highContrast') ?? false;
    _reduceMotion = p.getBool('reduceMotion') ?? false;
    _hasSeenOnboarding = p.getBool('hasSeenOnboarding') ?? false;
    _hapticEventsEnabled = p.getBool('hapticEventsEnabled') ?? true;
    _ttsEnabled = p.getBool('ttsEnabled') ?? false;
    _driverModeAutoLandscape = p.getBool('driverModeAutoLandscape') ?? false;
    _tripLogEnabled = p.getBool('tripLogEnabled') ?? true;
    _dashboardLayout = p.getStringList('dashboardLayout') ?? const [];
    _isReady = true;
    notifyListeners();
  }

  /// Clamp a persisted port value to the RFC 6335 user/registered range.
  /// Falls back to [fallback] when the stored value is missing or garbage.
  static int _clampPort(int? raw, int fallback) {
    if (raw == null) return fallback;
    if (raw < 1 || raw > 65535) return fallback;
    return raw;
  }

  /// Safely resolve an enum index persisted in SharedPreferences. If the
  /// stored index is out of range (e.g. the user downgraded after a new
  /// value was introduced, or prefs were corrupted), fall back to [fallback]
  /// instead of throwing `RangeError` and crashing app startup.
  static T _safeEnum<T>(List<T> values, int? index, T fallback) {
    if (index == null) return fallback;
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('autoConnect', _autoConnect);
      await p.setInt('connectionTimeout', _connectionTimeout);
      await p.setInt('portApi', _portApi);
      await p.setInt('portViz', _portViz);
      await p.setInt('portNav', _portNav);
      await p.setInt('portPages', _portPages);
      await p.setInt('speedUnit', _speedUnit.index);
      await p.setInt('gaugeMax', _gaugeMax.index);
      await p.setBool('showActivePlugins', _showActivePlugins);
      if (_language != null) {
        await p.setString('language', _language!);
      } else {
        await p.remove('language');
      }
      await p.setBool('mapAutoFollow', _mapAutoFollow);
      await p.setInt('mapTileStyle', _mapTileStyle.index);
      await p.setBool('mapShowRoute', _mapShowRoute);
      await p.setBool('vizDarkTheme', _vizDarkTheme);
      await p.setBool('vizAutoConnect', _vizAutoConnect);
      await p.setInt('accentColor', _accentColor.index);
      await p.setBool('highContrast', _highContrast);
      await p.setBool('reduceMotion', _reduceMotion);
      await p.setBool('hasSeenOnboarding', _hasSeenOnboarding);
      await p.setBool('hapticEventsEnabled', _hapticEventsEnabled);
      await p.setBool('ttsEnabled', _ttsEnabled);
      await p.setBool('driverModeAutoLandscape', _driverModeAutoLandscape);
      await p.setBool('tripLogEnabled', _tripLogEnabled);
      await p.setStringList('dashboardLayout', _dashboardLayout);
    } catch (e) {
      debugPrint('AppSettings._save error: $e');
    }
  }

  void setAutoConnect(bool v) {
    _autoConnect = v;
    _save();
    notifyListeners();
  }

  void setConnectionTimeout(int v) {
    _connectionTimeout = v.clamp(1, 60);
    _save();
    notifyListeners();
  }

  // Port setters clamp to 1..65535 at write-time as well as read-time.
  // Without this, a user who typed a value like 99999 would see it stick
  // in memory for the current session but silently snap back to the
  // fallback after the next app launch (where _clampPort runs on load).
  void setPortApi(int v) {
    _portApi = _clampPort(v, _portApi);
    _save();
    notifyListeners();
  }

  void setPortViz(int v) {
    _portViz = _clampPort(v, _portViz);
    _save();
    notifyListeners();
  }

  void setPortNav(int v) {
    _portNav = _clampPort(v, _portNav);
    _save();
    notifyListeners();
  }

  void setPortPages(int v) {
    _portPages = _clampPort(v, _portPages);
    _save();
    notifyListeners();
  }

  void setSpeedUnit(SpeedUnit v) {
    _speedUnit = v;
    _save();
    notifyListeners();
  }

  void setGaugeMax(GaugeMaxSpeed v) {
    _gaugeMax = v;
    _save();
    notifyListeners();
  }

  void setShowActivePlugins(bool v) {
    _showActivePlugins = v;
    _save();
    notifyListeners();
  }

  void setLanguage(String? lang) {
    _language = lang;
    _save();
    notifyListeners();
  }

  void clearLanguage() => setLanguage(null);
  void setMapAutoFollow(bool v) {
    _mapAutoFollow = v;
    _save();
    notifyListeners();
  }

  void setMapTileStyle(MapTileStyle v) {
    _mapTileStyle = v;
    _save();
    notifyListeners();
  }

  void setMapShowRoute(bool v) {
    _mapShowRoute = v;
    _save();
    notifyListeners();
  }

  void setVizDarkTheme(bool v) {
    _vizDarkTheme = v;
    _save();
    notifyListeners();
  }

  void setVizAutoConnect(bool v) {
    _vizAutoConnect = v;
    _save();
    notifyListeners();
  }

  void setAccentColor(AccentColor v) {
    _accentColor = v;
    _save();
    notifyListeners();
  }

  void setHighContrast(bool v) {
    _highContrast = v;
    _save();
    notifyListeners();
  }

  void setReduceMotion(bool v) {
    _reduceMotion = v;
    _save();
    notifyListeners();
  }

  void markOnboardingSeen() {
    if (_hasSeenOnboarding) return;
    _hasSeenOnboarding = true;
    _save();
    notifyListeners();
  }

  void setHapticEventsEnabled(bool v) {
    _hapticEventsEnabled = v;
    _save();
    notifyListeners();
  }

  void setTtsEnabled(bool v) {
    _ttsEnabled = v;
    _save();
    notifyListeners();
  }

  void setDriverModeAutoLandscape(bool v) {
    _driverModeAutoLandscape = v;
    _save();
    notifyListeners();
  }

  void setTripLogEnabled(bool v) {
    _tripLogEnabled = v;
    _save();
    notifyListeners();
  }

  /// Persist the user's dashboard card order. An empty list signals "use
  /// the default layout" so a fresh install stays on the built-in order.
  void setDashboardLayout(List<String> ids) {
    _dashboardLayout = List.unmodifiable(ids);
    _save();
    notifyListeners();
  }
}

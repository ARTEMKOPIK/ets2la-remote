import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedUnit { kmh, mph }
enum GaugeMaxSpeed { s160, s200, s250 }
enum MapTileStyle { dark, light, satellite }

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
      case GaugeMaxSpeed.s160: return 160;
      case GaugeMaxSpeed.s200: return 200;
      case GaugeMaxSpeed.s250: return 250;
    }
  }

  String speedDisplay(double kmh) {
    if (_speedUnit == SpeedUnit.mph) {
      return (kmh * 0.621371).toStringAsFixed(0);
    }
    return kmh.toStringAsFixed(0);
  }

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

  // ─────────────────────────────────────────────────────────────

  AppSettings() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _autoConnect = p.getBool('autoConnect') ?? false;
    _connectionTimeout = p.getInt('connectionTimeout') ?? 5;
    _portApi = p.getInt('portApi') ?? 37520;
    _portViz = p.getInt('portViz') ?? 37522;
    _portNav = p.getInt('portNav') ?? 62840;
    _portPages = p.getInt('portPages') ?? 37523;
    _speedUnit = SpeedUnit.values[p.getInt('speedUnit') ?? 0];
    _gaugeMax = GaugeMaxSpeed.values[p.getInt('gaugeMax') ?? 1];
    _showActivePlugins = p.getBool('showActivePlugins') ?? true;
    _language = p.getString('language'); // null = system default
    _mapAutoFollow = p.getBool('mapAutoFollow') ?? true;
    _mapTileStyle = MapTileStyle.values[p.getInt('mapTileStyle') ?? 0];
    _mapShowRoute = p.getBool('mapShowRoute') ?? true;
    _vizDarkTheme = p.getBool('vizDarkTheme') ?? true;
    _vizAutoConnect = p.getBool('vizAutoConnect') ?? true;
    notifyListeners();
  }

  Future<void> _save() async {
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
  }

  void setAutoConnect(bool v) { _autoConnect = v; _save(); notifyListeners(); }
  void setConnectionTimeout(int v) { _connectionTimeout = v; _save(); notifyListeners(); }
  void setPortApi(int v) { _portApi = v; _save(); notifyListeners(); }
  void setPortViz(int v) { _portViz = v; _save(); notifyListeners(); }
  void setPortNav(int v) { _portNav = v; _save(); notifyListeners(); }
  void setPortPages(int v) { _portPages = v; _save(); notifyListeners(); }
  void setSpeedUnit(SpeedUnit v) { _speedUnit = v; _save(); notifyListeners(); }
  void setGaugeMax(GaugeMaxSpeed v) { _gaugeMax = v; _save(); notifyListeners(); }
  void setShowActivePlugins(bool v) { _showActivePlugins = v; _save(); notifyListeners(); }
  void setLanguage(String? lang) { _language = lang; _save(); notifyListeners(); }
  void setMapAutoFollow(bool v) { _mapAutoFollow = v; _save(); notifyListeners(); }
  void setMapTileStyle(MapTileStyle v) { _mapTileStyle = v; _save(); notifyListeners(); }
  void setMapShowRoute(bool v) { _mapShowRoute = v; _save(); notifyListeners(); }
  void setVizDarkTheme(bool v) { _vizDarkTheme = v; _save(); notifyListeners(); }
  void setVizAutoConnect(bool v) { _vizAutoConnect = v; _save(); notifyListeners(); }
}

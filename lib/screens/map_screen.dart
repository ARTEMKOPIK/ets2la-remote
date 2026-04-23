import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/telemetry.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final MapController _mapController = MapController();
  bool? _autoFollowOverride; // null = use settings default
  LatLng? _lastPosition;
  DateTime _lastMapMove = DateTime.fromMillisecondsSinceEpoch(0);

  /// The TelemetryProvider we're currently listening to, so we can
  /// detach on dispose / when the provider changes.
  TelemetryProvider? _listeningTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to telemetry updates via a listener instead of watch() so
    // we can drive the map camera *outside* of build(). Re-wire the
    // subscription if the provider instance ever changes (hot reload).
    final telem = context.read<TelemetryProvider>();
    if (!identical(telem, _listeningTo)) {
      _listeningTo?.removeListener(_onTelemetryTick);
      telem.addListener(_onTelemetryTick);
      _listeningTo = telem;
    }
  }

  void _onTelemetryTick() {
    if (!mounted) return;
    final navPos = _listeningTo?.navPosition;
    if (navPos == null) return;
    final settings = context.read<AppSettings>();
    if (!(_autoFollowOverride ?? settings.mapAutoFollow)) return;
    final now = DateTime.now();
    if (navPos.position == _lastPosition) return;
    if (now.difference(_lastMapMove).inMilliseconds <= 500) return;
    _lastPosition = navPos.position;
    _lastMapMove = now;
    // Defer to the next frame so we don't collide with any in-flight build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(navPos.position, _mapController.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final navPos =
        context.select<TelemetryProvider, NavPosition?>((p) => p.navPosition);
    final navRoute =
        context.select<TelemetryProvider, NavRoute?>((p) => p.navRoute);
    final settings = context.watch<AppSettings>();

    final truckPos = navPos?.position;
    final bearing = navPos?.bearing ?? 0.0;
    final speedKmh = navPos?.speedKmh ?? 0;
    final speedText = settings.speedDisplay(speedKmh);
    final speedUnitLabel = settings.speedUnitLabel;
    final autoFollow = _autoFollowOverride ?? settings.mapAutoFollow;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.map ?? 'Map',
          style: const TextStyle(
              fontFamily: 'Roboto', fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              autoFollow
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              color:
                  autoFollow ? AppColors.orange : AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _autoFollowOverride = !autoFollow),
            tooltip:
                AppLocalizations.of(context)?.autoFollowTooltip ?? 'Auto-follow',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: truckPos ?? const LatLng(51.0, 10.0),
              initialZoom: 13,
              onTap: (_, __) => setState(() => _autoFollowOverride = false),
            ),
            children: [
              TileLayer(
                urlTemplate: settings.mapTileUrl,
                // No subdomains for satellite (ArcGIS), use {s} only for carto
                subdomains: settings.mapTileStyle == MapTileStyle.satellite
                    ? const []
                    : const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ets2la.remote',
                maxZoom: 19,
              ),

              // Route polyline
              if (settings.mapShowRoute &&
                  navRoute != null &&
                  navRoute.points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: navRoute.points,
                      strokeWidth: 4,
                      color: AppColors.orange.withOpacity(0.8),
                      borderColor: AppColors.orange.withOpacity(0.3),
                      borderStrokeWidth: 8,
                    ),
                  ],
                ),

              // Truck marker
              if (truckPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: truckPos,
                      width: 48,
                      height: 48,
                      child: Transform.rotate(
                        angle: bearing * (math.pi / 180),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Info overlay (top-left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded,
                          size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Semantics(
                        label: AppLocalizations.of(context)?.speed ?? 'Speed',
                        child: Text(
                          '$speedText $speedUnitLabel',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.explore_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${bearing.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // No GPS overlay
          if (truckPos == null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_off_rounded,
                        color: AppColors.textSecondary, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.noPositionData ??
                          'No position data',
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: AppColors.textSecondary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)?.enableNavigationPlugin ??
                          'Enable NavigationSockets plugin',
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: AppColors.textMuted,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _listeningTo?.removeListener(_onTelemetryTick);
    _mapController.dispose();
    super.dispose();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
          // RepaintBoundary isolates the high-frequency telemetry repaints
          // (~10Hz) from bubbling up to the rest of the widget tree. Without
          // it, every truck-position tick forces a repaint of the AppBar,
          // info overlay, etc.
          RepaintBoundary(
            child: FlutterMap(
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
                  // Must match the real application id so OSM/Carto can
                  // identify and rate-limit our traffic per their UA policy.
                  userAgentPackageName: 'com.ets2la.ets2la_remote',
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

              // Tile-provider attribution. Required by OSM/Carto/ArcGIS ToS
              // — omitting it is cause for tile-server rate-limiting or an
              // outright block. Collapsible so it doesn't cover the map.
              _buildAttribution(context, settings.mapTileStyle),
              ],
            ),
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

          // Tile-style quick switcher — three compact circle buttons in the
          // top-right corner, matching Google Maps' satellite/street toggle.
          // The full settings screen still has the same option, but most
          // users never find it — this surfaces the feature inline.
          Positioned(
            top: 12,
            right: 12,
            child: _TileStyleSwitcher(
              current: settings.mapTileStyle,
              onSelect: (style) {
                context.read<AppSettings>().setMapTileStyle(style);
              },
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

  /// Build a [RichAttributionWidget] appropriate for the currently-selected
  /// tile provider. Complying with each provider's attribution ToS is
  /// required to avoid rate-limiting or tile-server bans.
  Widget _buildAttribution(BuildContext context, MapTileStyle style) {
    Future<void> openUrl(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    final List<TextSourceAttribution> items;
    switch (style) {
      case MapTileStyle.satellite:
        items = [
          TextSourceAttribution(
            'Esri World Imagery',
            onTap: () => openUrl('https://www.arcgis.com/home/item.html?id=10df2279f9684e4a9f6a7f08febac2a9'),
          ),
        ];
        break;
      case MapTileStyle.dark:
      case MapTileStyle.light:
        items = [
          TextSourceAttribution(
            '© OpenStreetMap contributors',
            onTap: () => openUrl('https://www.openstreetmap.org/copyright'),
          ),
          TextSourceAttribution(
            '© CARTO',
            onTap: () => openUrl('https://carto.com/attributions'),
          ),
        ];
        break;
    }

    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: items,
    );
  }
}

/// Compact 3-button overlay letting the user flip between map tile styles
/// without leaving the map screen. Mirrors the dropdown in Settings →
/// Appearance; the backing state lives in [AppSettings.mapTileStyle] so
/// switching here persists across launches.
class _TileStyleSwitcher extends StatelessWidget {
  final MapTileStyle current;
  final ValueChanged<MapTileStyle> onSelect;

  const _TileStyleSwitcher({
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TileStyleButton(
            icon: Icons.dark_mode_rounded,
            tooltip: l10n?.mapStyleDark ?? 'Dark',
            selected: current == MapTileStyle.dark,
            onTap: () => onSelect(MapTileStyle.dark),
          ),
          _TileStyleButton(
            icon: Icons.light_mode_rounded,
            tooltip: l10n?.mapStyleLight ?? 'Light',
            selected: current == MapTileStyle.light,
            onTap: () => onSelect(MapTileStyle.light),
          ),
          _TileStyleButton(
            icon: Icons.satellite_alt_rounded,
            tooltip: l10n?.mapStyleSatellite ?? 'Satellite',
            selected: current == MapTileStyle.satellite,
            onTap: () => onSelect(MapTileStyle.satellite),
          ),
        ],
      ),
    );
  }
}

class _TileStyleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _TileStyleButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      selected: selected,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.orangeDim : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.orange
                    : AppColors.surfaceBorder.withOpacity(0.5),
                width: selected ? 1.2 : 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected ? AppColors.orange : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

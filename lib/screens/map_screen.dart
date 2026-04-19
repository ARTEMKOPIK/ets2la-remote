import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final telem = context.watch<TelemetryProvider>();
    final settings = context.watch<AppSettings>();
    final navPos = telem.navPosition;
    final navRoute = telem.navRoute;

    // Auto-follow — throttled to max 2fps (every 500ms) to save CPU on weak devices
    final now = DateTime.now();
    if ((_autoFollowOverride ?? settings.mapAutoFollow) &&
        navPos != null &&
        navPos.position != _lastPosition &&
        now.difference(_lastMapMove).inMilliseconds > 500) {
      _lastPosition = navPos.position;
      _lastMapMove = now;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(navPos.position, _mapController.camera.zoom);
        }
      });
    }

    final truckPos = navPos?.position;
    final bearing = navPos?.bearing ?? 0.0;
    final speedKmh = (navPos?.speedKmh ?? 0).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              (_autoFollowOverride ?? settings.mapAutoFollow) ? Icons.my_location_rounded : Icons.location_searching_rounded,
              color: (_autoFollowOverride ?? settings.mapAutoFollow) ? AppColors.orange : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _autoFollowOverride = !(_autoFollowOverride ?? settings.mapAutoFollow)),
            tooltip: 'Auto-follow',
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
              if (settings.mapShowRoute && navRoute != null && navRoute.points.length >= 2)
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
                        angle: bearing * (3.14159 / 180),
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
                      const Icon(Icons.speed_rounded, size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '$speedKmh km/h',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.explore_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${bearing.toStringAsFixed(0)}°',
                        style: GoogleFonts.inter(
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
                      'No position data',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable NavigationSockets plugin',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

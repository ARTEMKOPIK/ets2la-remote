import 'package:latlong2/latlong.dart';

class NavPosition {
  final LatLng position;
  final double bearing;
  final double speedMph;

  const NavPosition({
    required this.position,
    this.bearing = 0,
    this.speedMph = 0,
  });

  factory NavPosition.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as List?;
    return NavPosition(
      position: pos != null && pos.length >= 2
          ? LatLng((pos[1] as num).toDouble(), (pos[0] as num).toDouble())
          : const LatLng(0, 0),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
      speedMph: (json['speedMph'] as num?)?.toDouble() ?? 0,
    );
  }

  double get speedKmh => speedMph * 1.60934;
}

class NavRoute {
  final String id;
  final List<LatLng> points;

  const NavRoute({this.id = '', this.points = const []});

  factory NavRoute.fromJson(Map<String, dynamic> json) {
    final segments = json['segments'] as List? ?? [];
    final List<LatLng> pts = [];
    for (final seg in segments) {
      final lonLats = seg['lonLats'] as List? ?? [];
      for (final ll in lonLats) {
        if (ll is List && ll.length >= 2) {
          pts.add(LatLng((ll[1] as num).toDouble(), (ll[0] as num).toDouble()));
        }
      }
    }
    return NavRoute(id: json['id'] as String? ?? '', points: pts);
  }
}

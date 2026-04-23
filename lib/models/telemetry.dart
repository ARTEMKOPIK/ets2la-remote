import 'package:latlong2/latlong.dart';

/// Defensive coercion for JSON numerics. The ETS2LA backend has been
/// observed sending `null`, numeric strings, and (rarely) bools where
/// numbers are expected; a hard cast would bring down the whole telemetry
/// pipeline, so we normalise up front instead.
double _num(Object? raw, [double fallback = 0]) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? fallback;
  return fallback;
}

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
    final pos = json['position'];
    double lon = 0;
    double lat = 0;
    if (pos is List && pos.length >= 2) {
      lon = _num(pos[0]);
      lat = _num(pos[1]);
    }
    return NavPosition(
      position: LatLng(lat, lon),
      bearing: _num(json['bearing']),
      speedMph: _num(json['speedMph']),
    );
  }

  double get speedKmh => speedMph * 1.60934;
}

class NavRoute {
  final String id;
  final List<LatLng> points;

  const NavRoute({this.id = '', this.points = const []});

  factory NavRoute.fromJson(Map<String, dynamic> json) {
    final segments = json['segments'];
    final List<LatLng> pts = [];
    if (segments is List) {
      for (final seg in segments) {
        if (seg is! Map) continue;
        final lonLats = seg['lonLats'];
        if (lonLats is! List) continue;
        for (final ll in lonLats) {
          if (ll is List && ll.length >= 2) {
            pts.add(LatLng(_num(ll[1]), _num(ll[0])));
          }
        }
      }
    }
    return NavRoute(id: json['id'] is String ? json['id'] as String : '', points: pts);
  }
}

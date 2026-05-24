// Shared types used by the routing client.

class LatLng {
  final double lat;
  final double lon;
  const LatLng(this.lat, this.lon);
  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};
  factory LatLng.fromJson(Map<String, dynamic> j) =>
      LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble());
}

enum CostingType {
  auto('auto'),
  bicycle('bicycle'),
  scooter('scooter'),
  pedestrian('pedestrian'),
  truck('truck'),
  motorcycle('motorcycle'),
  motorScooter('motor_scooter');

  final String wire;
  const CostingType(this.wire);
}

enum Units {
  kilometers('kilometers'),
  miles('miles');

  final String wire;
  const Units(this.wire);
}

class RouteOptions {
  final CostingType? costing;

  /// Sent as `directions_options.language`. When `null`, the effective
  /// locale (per-call → client → `'en'`) is used.
  final String? language;

  /// Per-call locale override. Sent as the `?locale=` query parameter and
  /// the `Accept-Language` header for this single request.
  final String? locale;

  final Units units;
  final int? alternates;
  final bool simplifiedInstructions;

  const RouteOptions({
    this.costing,
    this.language,
    this.locale,
    this.units = Units.kilometers,
    this.alternates,
    this.simplifiedInstructions = false,
  });
}

class IsochroneContour {
  /// Time in minutes.
  final double? timeMin;
  /// Distance in km.
  final double? distanceKm;
  const IsochroneContour({this.timeMin, this.distanceKm});

  Map<String, dynamic> toJson() => {
        if (timeMin != null) 'time': timeMin,
        if (distanceKm != null) 'distance': distanceKm,
      };
}

class IsochroneOptions {
  final List<IsochroneContour> contours;
  final CostingType? costing;
  final bool polygons;
  final String? locale;
  const IsochroneOptions({
    required this.contours,
    this.costing,
    this.polygons = true,
    this.locale,
  });
}

/// Single shape pointer in the unified API. The server response is left as
/// a plain `Map<String, dynamic>` — apps that want strong typing on the
/// `trip` block can wrap it themselves.

class RoutingException implements Exception {
  final String message;
  final int? statusCode;
  RoutingException(this.message, [this.statusCode]);
  @override
  String toString() => 'RoutingException(status=$statusCode, $message)';
}

/// Scoova routing — standalone Routing client for the Scoova routing
/// gateway (`api.scoo-va.info/api/v1/routing`).
///
/// Eight endpoints: route, optimizedRoute, isochrone, matrix, height
/// (alias elevation), mapMatch, locate, status. Plus polyline6 decoding.
library scoova_routing;

export 'src/types.dart';
export 'src/client.dart';

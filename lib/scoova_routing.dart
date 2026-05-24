/// Scoova routing — standalone Valhalla client for `routing.scoo-va.info`.
///
/// Eight endpoints: route, optimizedRoute, isochrone, matrix, height
/// (alias elevation), mapMatch, locate, status. Plus polyline6 decoding.
library scoova_routing;

export 'src/types.dart';
export 'src/client.dart';

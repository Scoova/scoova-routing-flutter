import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'types.dart';

const String _defaultBase = 'https://routing.scoo-va.info';

/// Standalone Valhalla routing client for `routing.scoo-va.info`.
///
/// Eight endpoints: route, optimizedRoute, isochrone, matrix, height
/// (alias elevation), mapMatch, locate, status.
///
/// Pass [locale] once (e.g. `'fr'`, `'ar-EG'`, `'pt-BR'`) and every request
/// carries it as both the `?locale=` query parameter and the `Accept-Language`
/// header. Per-call `RouteOptions.locale` / `IsochroneOptions.locale`
/// overrides. Default `'en'`. Pass [apiKey] when going through the
/// `api.scoo-va.info` gateway — sent as `X-API-Key` on every request.
class RoutingClient {
  final String _baseUrl;
  final CostingType _defaultCosting;
  final String _locale;
  final String? _apiKey;
  final http.Client _http;

  RoutingClient({
    String baseUrl = _defaultBase,
    CostingType defaultCosting = CostingType.scooter,
    String locale = 'en',
    String? apiKey,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _defaultCosting = defaultCosting,
        _locale = locale,
        _apiKey = apiKey,
        _http = httpClient ?? http.Client();

  void close() => _http.close();

  // ─── Endpoints ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> route(
    List<LatLng> locations, {
    RouteOptions options = const RouteOptions(),
  }) {
    final effectiveLocale = options.locale ?? _locale;
    final body = <String, dynamic>{
      'locations': locations.map((l) => l.toJson()).toList(),
      'costing': (options.costing ?? _defaultCosting).wire,
      'directions_options': {
        'units': options.units.wire,
        'language': options.language ?? effectiveLocale,
      },
      if (options.simplifiedInstructions) 'simplified_instructions': true,
      if (options.alternates != null) 'alternates': options.alternates,
    };
    return _post('/route', body, locale: effectiveLocale);
  }

  Future<Map<String, dynamic>> optimizedRoute(
    List<LatLng> locations, {
    RouteOptions options = const RouteOptions(),
  }) {
    final effectiveLocale = options.locale ?? _locale;
    final body = <String, dynamic>{
      'locations': locations.map((l) => l.toJson()).toList(),
      'costing': (options.costing ?? _defaultCosting).wire,
      'directions_options': {
        'units': options.units.wire,
        'language': options.language ?? effectiveLocale,
      },
    };
    return _post('/optimized_route', body, locale: effectiveLocale);
  }

  Future<Map<String, dynamic>> isochrone(
    LatLng location,
    IsochroneOptions options,
  ) {
    final effectiveLocale = options.locale ?? _locale;
    return _post('/isochrone', {
      'locations': [location.toJson()],
      'costing': (options.costing ?? _defaultCosting).wire,
      'contours': options.contours.map((c) => c.toJson()).toList(),
      'polygons': options.polygons,
    }, locale: effectiveLocale);
  }

  Future<Map<String, dynamic>> matrix({
    required List<LatLng> sources,
    required List<LatLng> targets,
    CostingType costing = CostingType.scooter,
  }) {
    return _post('/sources_to_targets', {
      'sources': sources.map((l) => l.toJson()).toList(),
      'targets': targets.map((l) => l.toJson()).toList(),
      'costing': costing.wire,
    });
  }

  Future<Map<String, dynamic>> height(
    List<LatLng> shape, {
    bool range = true,
  }) {
    return _post('/height', {
      'shape': shape.map((l) => l.toJson()).toList(),
      'range': range,
    });
  }

  /// Alias for [height] — matches the unified SDK naming.
  Future<Map<String, dynamic>> elevation(
    List<LatLng> shape, {
    bool range = true,
  }) =>
      height(shape, range: range);

  Future<Map<String, dynamic>> mapMatch(
    List<LatLng> shape, {
    CostingType costing = CostingType.scooter,
  }) {
    return _post('/trace_route', {
      'shape': shape.map((l) => l.toJson()).toList(),
      'costing': costing.wire,
      'shape_match': 'map_snap',
    });
  }

  Future<Map<String, dynamic>> locate(
    List<LatLng> locations, {
    CostingType costing = CostingType.scooter,
  }) {
    return _post('/locate', {
      'locations': locations.map((l) => l.toJson()).toList(),
      'costing': costing.wire,
    });
  }

  Future<Map<String, dynamic>> status() => _get('/status');

  // ─── Internals ────────────────────────────────────────────────────────

  Uri _urlFor(String path, {String? locale}) {
    final effective = locale ?? _locale;
    return Uri.parse('$_baseUrl$path').replace(queryParameters: {
      'locale': effective,
    });
  }

  Map<String, String> _headers({String? locale, bool includeContentType = false}) {
    final h = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': locale ?? _locale,
    };
    if (includeContentType) h['Content-Type'] = 'application/json';
    final key = _apiKey;
    if (key != null) h['X-API-Key'] = key;
    return h;
  }

  Future<Map<String, dynamic>> _post(String path, Object body, {String? locale}) async {
    final res = await _http.post(
      _urlFor(path, locale: locale),
      headers: _headers(locale: locale, includeContentType: true),
      body: jsonEncode(body),
    );
    return _decode(res, path);
  }

  Future<Map<String, dynamic>> _get(String path, {String? locale}) async {
    final res = await _http.get(
      _urlFor(path, locale: locale),
      headers: _headers(locale: locale),
    );
    return _decode(res, path);
  }

  Map<String, dynamic> _decode(http.Response res, String path) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RoutingException(
        'HTTP ${res.statusCode} ${res.reasonPhrase ?? ''}: ${res.body.substring(0, math.min(200, res.body.length))}',
        res.statusCode,
      );
    }
    final body = res.body;
    if (body.isEmpty) return {};
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
      return {'data': v};
    } catch (e) {
      throw RoutingException('Invalid JSON from $path: $e');
    }
  }
}

/// Decode a Valhalla polyline6 string into `List<LatLng>`.
List<LatLng> decodePolyline(String encoded, {int precision = 6}) {
  final coords = <LatLng>[];
  final factor = math.pow(10, precision).toDouble();
  var index = 0;
  var lat = 0;
  var lon = 0;
  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lon += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    coords.add(LatLng(lat / factor, lon / factor));
  }
  return coords;
}

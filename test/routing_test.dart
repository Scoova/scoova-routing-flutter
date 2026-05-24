import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scoova_routing/scoova_routing.dart';
import 'package:test/test.dart';

const _okTrip = '{"trip":{"legs":[],"summary":{"length":0,"time":0},"status":0,"status_message":"OK","units":"kilometers"}}';

void main() {
  test('route — hits POST /route with sane defaults', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200, headers: {'content-type': 'application/json'});
      }),
    );
    await client.route([const LatLng(30, 31), const LatLng(31, 32)]);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/route');
    expect(captured.url.queryParameters['locale'], 'en');
    expect(captured.headers['Accept-Language'], 'en');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['locations'] as List).length, 2);
    expect(body['costing'], 'scooter');
    expect((body['directions_options'] as Map)['language'], 'en');
  });

  test('client-level locale flows into URL + header + directions_options', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      locale: 'fr',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200);
      }),
    );
    await client.route([const LatLng(30, 31), const LatLng(31, 32)]);
    expect(captured.url.queryParameters['locale'], 'fr');
    expect(captured.headers['Accept-Language'], 'fr');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['directions_options'] as Map)['language'], 'fr');
  });

  test('per-call locale overrides client default', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      locale: 'fr',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200);
      }),
    );
    await client.route(
      [const LatLng(30, 31), const LatLng(31, 32)],
      options: const RouteOptions(locale: 'ar-EG'),
    );
    expect(captured.url.queryParameters['locale'], 'ar-EG');
    expect(captured.headers['Accept-Language'], 'ar-EG');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['directions_options'] as Map)['language'], 'ar-EG');
  });

  test('apiKey flows into X-API-Key header', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      apiKey: 'demo',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200);
      }),
    );
    await client.route([const LatLng(30, 31), const LatLng(31, 32)]);
    expect(captured.headers['X-API-Key'], 'demo');
  });

  test('respects costing + language + alternates', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200);
      }),
    );
    await client.route(
      [const LatLng(30, 31), const LatLng(31, 32)],
      options: const RouteOptions(
        costing: CostingType.pedestrian,
        language: 'ar-EG',
        alternates: 2,
        simplifiedInstructions: true,
      ),
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['costing'], 'pedestrian');
    expect((body['directions_options'] as Map)['language'], 'ar-EG');
    expect(body['alternates'], 2);
    expect(body['simplified_instructions'], true);
  });

  test('matrix hits /sources_to_targets', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await client.matrix(
      sources: const [LatLng(30, 31)],
      targets: const [LatLng(31, 32)],
    );
    expect(captured.url.path, '/sources_to_targets');
  });

  test('isochrone hits /isochrone with contours', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await client.isochrone(
      const LatLng(30, 31),
      const IsochroneOptions(contours: [IsochroneContour(timeMin: 5)]),
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect((body['contours'] as List).length, 1);
    expect((body['contours'] as List).first['time'], 5);
    expect(body['polygons'], true);
  });

  test('elevation is an alias for /height', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await client.elevation(const [LatLng(30, 31)]);
    expect(captured.url.path, '/height');
  });

  test('mapMatch hits /trace_route with shape_match=map_snap', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response(_okTrip, 200);
      }),
    );
    await client.mapMatch(const [LatLng(30, 31), LatLng(31, 32)]);
    expect(captured.url.path, '/trace_route');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['shape_match'], 'map_snap');
  });

  test('locate hits /locate', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await client.locate(const [LatLng(30, 31)]);
    expect(captured.url.path, '/locate');
  });

  test('status hits GET /status', () async {
    late http.Request captured;
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        captured = req;
        return http.Response('{}', 200);
      }),
    );
    await client.status();
    expect(captured.method, 'GET');
    expect(captured.url.path, '/status');
  });

  test('non-2xx throws RoutingException', () async {
    final client = RoutingClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async => http.Response('boom', 502)),
    );
    await expectLater(
      client.route([const LatLng(30, 31), const LatLng(31, 32)]),
      throwsA(isA<RoutingException>()),
    );
  });

  test('decodePolyline decodes canonical fixture', () {
    final coords = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(coords.length, 3);
  });
}

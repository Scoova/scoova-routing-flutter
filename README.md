# scoova_routing

Routing client for `routing.scoo-va.info`. Pure Dart,
no Flutter dependency — works in CLI / server / Flutter projects identically.

## Install

```sh
dart pub add scoova_routing
# or
flutter pub add scoova_routing
```

## Usage

```dart
import 'package:scoova_routing/scoova_routing.dart';

final client = RoutingClient(
  locale: 'ar-EG',                                 // every request gets ?locale=ar-EG + Accept-Language
  apiKey: const String.fromEnvironment('SCOOVA_API_KEY'),
);

final result = await client.route(
  [const LatLng(30.04, 31.24), const LatLng(30.06, 31.25)],
  options: const RouteOptions(costing: CostingType.scooter),
);

final shape = (result['trip'] as Map)['legs'][0]['shape'] as String;
final path = decodePolyline(shape);
```

## Endpoints

`route`, `optimizedRoute`, `isochrone`, `matrix`, `height` (alias `elevation`),
`mapMatch`, `locate`, `status`.

## Locale

Pass `locale` once on the client and every call carries it as both the
`?locale=` query parameter and the `Accept-Language` HTTP header. Per-call
`RouteOptions.locale` overrides the client default. The server falls back to
`en` for any unsupported code.

## Build + test

```sh
dart pub get
dart analyze
dart test
```

Repo: <https://github.com/Scoova/scoova-routing-flutter>.
License: Apache-2.0.

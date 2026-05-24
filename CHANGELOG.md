# Changelog

All notable changes to `scoova_routing` (Dart / Flutter) are recorded here.
This project follows [Semantic Versioning](https://semver.org/).

## 1.1.0 — 2026-05-25

First public release. Standalone Valhalla routing client for
`routing.scoo-va.info`, extracted from the unified `scoova_sdk` package (now
retired into `_legacy_unified_sdk_2026-05-25/`).

### Endpoints (verified parity across all 5 platforms)

`route`, `optimizedRoute`, `isochrone`, `matrix`, `height` (alias `elevation`),
`mapMatch`, `locate`, `status`.

### Features

- Built-in locale support — pass `locale: 'fr'` / `'ar-EG'` / `'pt-BR'`
  once and every request carries it as both the `?locale=` query parameter
  and the `Accept-Language` header. Per-call `RouteOptions.locale` /
  `IsochroneOptions.locale` override. Default `'en'`.
- `apiKey` constructor argument — sent as `X-API-Key` when set, for calls
  routed through the `api.scoo-va.info/v1/routing/*` gateway.
- Pluggable `http.Client` (`package:http`) for tests + shared transports.
- Polyline6 decoder included.
- Pure Dart, no Flutter dependency — works in CLI / server / Flutter
  projects identically.

### Repo

<https://github.com/Scoova/scoova-routing-flutter>

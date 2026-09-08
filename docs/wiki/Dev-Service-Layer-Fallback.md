# Service Layer & Fallback

Every external data source (country API, geocoder, charging map) is wrapped in a **service chain** that gives you:

- Fresh-first reads with request coalescing
- Explicit stale fallback
- Accumulated errors per attempt
- Structured source attribution
- Per-Dio rate limiting

## The core type — `ServiceResult<T>`

`lib/core/services/service_result.dart:34–59`

```dart
class ServiceResult<T> {
  final T data;
  final ServiceSource source;     // enum: tankerkoenigApi, prixCarburantsApi,
                                  //       eControlApi, cache, demo, ...
  final DateTime fetchedAt;
  final bool isStale;
  final List<ServiceError> errors;

  String get freshnessLabel;      // "< 1 min", "5 min", "2 h", "3 d"
}

class ServiceError { ServiceSource source; String message; int? statusCode; DateTime occurredAt; }
```

Every `ServiceResult` carries its provenance. The UI uses `freshnessLabel` and `isStale` for the per-result badge; it uses `errors` for a "Tried 3 sources" diagnostic summary.

## `StationServiceChain` — the canonical chain

`lib/core/services/station_service_chain.dart:22`

```
fetch(key, service):
  1. cached = CacheManager.getFresh(key)
       hit?   return ServiceResult(cached.data, source: cache, isStale: false)

  2. try service.fetch(params)
       ok?   CacheManager.put(key, result) and
             return ServiceResult(data, source: service.source, isStale: false)
       err?  push to errors list, continue

  3. stale = CacheManager.get(key)
       hit?   return ServiceResult(stale.data, source: cache, isStale: true, errors: [...])

  4. throw ServiceChainExhaustedException(errors)
```

### Request coalescing

```dart
final Map<String, Future<ServiceResult<T>>> _inFlight = {};
final Map<String, DateTime> _inFlightTimestamps = {};
```

If two widgets kick off the same fetch (e.g. map and list rebuilding concurrently), the second one attaches to the first Future instead of doubling the HTTP call. Entries auto-evict after 2 min.

## Country registry

`lib/core/services/country_service_registry.dart:77–134`

17 countries, each with a concrete `StationService` under `lib/features/station_services/<country>/`:

| Country | Service file | API base |
|---|---|---|
| DE | `germany/tankerkoenig_station_service.dart` | creativecommons.tankerkoenig.de |
| FR | `france/prix_carburants_station_service.dart` | data.gouv.fr |
| AT | `austria/econtrol_station_service.dart` | e-control.at |
| ES | `spain/miteco_station_service.dart` | sedeaplicaciones.mineco.gob.es |
| IT | `italy/mise_station_service.dart` | dgsaie.mise.gov.it |
| DK | `denmark/denmark_station_service.dart` | OK / Shell DK |
| PT | `portugal/portugal_station_service.dart` | DGEG |
| LU | `luxembourg/luxembourg_station_service.dart` | gouvernement.lu open data |
| SI | `slovenia/slovenia_station_service.dart` | Petrol / OMV SI open data |
| GB | `uk/uk_station_service.dart` | UK open data |
| AR | `argentina/argentina_station_service.dart` | Energia Argentina (HTTPS enforced — #731) |
| AU | `australia/australia_station_service.dart` | Government open data |
| MX | `mexico/mexico_station_service.dart` | CRE |
| KR | `south_korea/south_korea_station_service.dart` | Opinet |
| CL | `chile/chile_station_service.dart` | Bencina en Línea |
| GR | `greece/greece_station_service.dart` | Government open data |
| RO | `romania/romania_station_service.dart` | Government open data |

Plus `lib/core/services/impl/demo_station_service.dart` for fallback / UI preview.

Resolve the right one with `stationServiceProvider` keyed on the active country:

```dart
@riverpod
StationService stationService(Ref ref) {
  final country = ref.watch(activeCountryProvider);
  return ref.watch(_stationServiceFor(country.code));
}
```

## `GeocodingChain`

`lib/core/services/geocoding_chain.dart:24–30`

Five-step chain (one more than stations):

1. Fresh cache hit + coords inside country bounding box
2. `NativeGeocodingProvider` (Android/iOS built-in geocoder)
3. `NominatimGeocodingProvider` (public OSM service)
4. Stale cache hit + bounding-box validation
5. Throw `ServiceChainExhaustedException`

Bounding-box validation is the extra step: Android's native geocoder occasionally returns coordinates in the wrong country for ambiguous ZIPs; we reject those and fall through to Nominatim.

## `DioFactory` and rate limiting

`lib/core/network/dio_factory.dart:15–48`

```dart
Dio create({
  required String baseUrl,
  Duration? connectTimeout,
  Duration? receiveTimeout,
  RateLimitConfig? rateLimit = const RateLimitConfig.defaults(),
  List<Interceptor>? extraInterceptors,
}) {
  final dio = Dio(...);
  if (rateLimit != null) dio.interceptors.add(RateLimitInterceptor(rateLimit));
  // ...
}
```

Every Dio gets a `RateLimitInterceptor` by default. Opt out (`rateLimit: null`) only for user-triggered one-shots where throttling hurts UX.

### `RateLimitInterceptor`
`lib/core/network/rate_limit_interceptor.dart:18–61`

- Per-Dio (not global) future gate
- Default `minInterval = 1 s`, default jitter 500 ms
- Serialises requests; if a call arrives before `minInterval` has passed, it awaits
- Jitter prevents thundering herd when the app wakes from background

### Recommended defaults

| API | minInterval | jitter |
|---|---|---|
| Tankerkoenig (DE) | 2 s | 500–2500 ms |
| Nominatim | 1 s | 500 ms |
| OpenStreetMap tiles | 500 ms | 0 |
| OpenChargeMap | 1 s | 500 ms |
| Routing (OSRM) | 500 ms | 0 |

Set via `DioFactory.create(..., rateLimit: RateLimitConfig(minInterval: 2 s, jitter: 2 s))`.

## Writing a new service

Conform to the interface:

```dart
abstract class StationService {
  ServiceSource get source;
  Future<List<Station>> fetch(SearchParams params);
}
```

Then register it in `country_service_registry.dart` with its country code. The chain, cache, rate limiting, and ServiceResult wrapping are given for free.

See [Adding a Country](Dev-Adding-A-Country) for the step-by-step.

## Related

- [Caching Strategy](Dev-Caching-Strategy) — how the cache layer works
- [Error Reporting & Tracing](Dev-Error-Reporting-Tracing) — how ServiceChainExhaustedException flows to the trace recorder

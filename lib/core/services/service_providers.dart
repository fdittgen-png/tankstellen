// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../cache/cache_manager.dart';
import '../country/country_provider.dart';
import '../telemetry/integrations/dio_trace_interceptor.dart';
import '../storage/storage_providers.dart';
import 'country_service_registry.dart';
import 'dio_factory.dart';
import 'geocoding_chain.dart';
import 'impl/native_geocoding_provider.dart';
import 'impl/nominatim_geocoding_provider.dart';
import 'service_config.dart';
import 'station_service.dart';

part 'service_providers.g.dart';

// ---------------------------------------------------------------------------
// Dio instance for Tankerkoenig (API key interceptor + default rate limit
// from DioFactory + trace logging)
// ---------------------------------------------------------------------------

/// The Tankerkönig Dio — rate limited, API-key injecting, trace logging.
///
/// #4381 — `keepAlive`: the returned Dio is **retained** by the
/// [stationServiceProvider] chain, which is itself `keepAlive`. Under the
/// previous auto-dispose declaration the provider element was torn down the
/// moment the registry's `ref.read` returned (nothing ever listens to it),
/// while the service went on using the instance for the rest of the session.
/// Matching the lifetime of the consumer is half the fix; the other half is
/// that no interceptor installed here may hold a `Ref` (see
/// [_ApiKeyInterceptor]), so not even a full container teardown can break a
/// Dio that is already in someone's hands.
@Riverpod(keepAlive: true)
Dio tankerkoenigDio(Ref ref) {
  final config = ServiceConfigs.tankerkoenig;
  // Tankerkoenig's published policy is one request per ~5s; we use 2s with
  // 500 ms jitter, which combined with the cache + service chain stays well
  // under the limit while keeping the UI responsive.
  final dio = DioFactory.create(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    rateLimit: const Duration(seconds: 2),
    rateLimitJitterRangeMs: 500,
  );

  // Inject API key from user settings. #3592 — the DE key has ONE accessor,
  // [apiKeyStorageProvider]; #4381 — the interceptor gets a resolver bound to
  // that keepAlive value, never the `Ref` itself.
  final apiKeys = ref.watch(apiKeyStorageProvider);
  dio.interceptors.add(_ApiKeyInterceptor(() => apiKeys.getApiKey('de')));
  // Record HTTP errors in trace log
  dio.interceptors.add(DioTraceInterceptor(ref));

  return dio;
}

// ---------------------------------------------------------------------------
// Station service with full fallback chain
// ---------------------------------------------------------------------------

/// Returns the appropriate station service based on the active country.
///
/// Delegates to [CountryServiceRegistry], which is the single source of
/// truth for per-country service wiring — including Germany. Countries
/// that require an API key fall back to [DemoStationService] from inside
/// the registry's factory function when no key is configured.
///
/// #2264 — `keepAlive`: bulk-dataset services (ES/IT/AR/DK) hold the parsed
/// whole-country dataset in instance fields. Under the previous auto-dispose
/// provider the service was rebuilt — and the in-memory dataset thrown away —
/// every time the last listener detached, forcing a re-download far more
/// often than the dataset's TTL. Keeping the provider alive lets the dataset
/// (and its persisted Hive read-through) survive across the session; it still
/// rebuilds when [activeCountryProvider] changes, which is the only time the
/// service identity should change.
@Riverpod(keepAlive: true)
StationService stationService(Ref ref) {
  final country = ref.watch(activeCountryProvider);
  return _resolveServiceForCountry(ref, country.code);
}

/// Cross-country station service lookup (#753 widget tap path, #514
/// favorites currency, #515 route search). Resolves the
/// [StationService] for an arbitrary [countryCode] without changing
/// the active country.
///
/// Exposed as a `Provider.family` so tests can override per-country
/// services without standing up the full `CountryServiceRegistry`.
/// Production paths use the [stationServiceForCountry] sync helper.
///
/// #2264 — `keepAlive` for the same bulk-dataset reason as
/// [stationServiceProvider]: a per-country bulk service keeps its parsed
/// dataset alive across rebuilds instead of re-downloading the whole country
/// on every cross-country lookup.
@Riverpod(keepAlive: true)
StationService perCountryStationService(
  Ref ref,
  String countryCode,
) {
  return _resolveServiceForCountry(ref, countryCode);
}

/// Sync helper preserved for the legacy call sites that haven't moved
/// to the provider family yet. Goes through
/// [perCountryStationServiceProvider] so a test override on the
/// family applies here too — that's the seam the #753 widget-tap
/// regression test relies on.
StationService stationServiceForCountry(Ref ref, String countryCode) =>
    ref.read(perCountryStationServiceProvider(countryCode));

StationService _resolveServiceForCountry(Ref ref, String countryCode) {
  final cache = ref.read(cacheManagerProvider);
  return CountryServiceRegistry.buildService(countryCode, ref, cache);
}

// ---------------------------------------------------------------------------
// Geocoding with fallback chain: native → Nominatim → cache
// ---------------------------------------------------------------------------

@riverpod
GeocodingChain geocodingChain(Ref ref) {
  final cache = ref.watch(cacheManagerProvider);
  final country = ref.watch(activeCountryProvider);
  // Nominatim first — it's deterministic, country-aware, and handles
  // structured inputs (postal codes + French arrondissement hints)
  // reliably. Native geocoding can silently return the device's last
  // known GPS position on some Android builds when the query doesn't
  // match cleanly, poisoning the search with local coords (#690).
  return GeocodingChain(
    [
      NominatimGeocodingProvider(countryCode: country.code), // All platforms
      NativeGeocodingProvider(countryName: country.name), // Android/iOS fallback
    ],
    cache,
    countryCode: country.code,
  );
}

// ---------------------------------------------------------------------------
// Interceptors (moved from dio_client.dart, now private to this file)
// ---------------------------------------------------------------------------

/// Resolves the configured API key at request time.
///
/// Deliberately a plain callback rather than a Riverpod `Ref` (#4381): a Dio
/// instance outlives the provider that built it — the station-service chain
/// holds it for the whole session — so a `Ref` captured here is read after
/// its element was disposed and every request dies with
/// `DioException [unknown]: Cannot use the Ref ... after it has been
/// disposed`. Bind the resolver to a keepAlive value instead, and the
/// interceptor's lifetime stops depending on Riverpod's.
typedef ApiKeyResolver = String? Function();

// Key für den Zugriff auf die freie Tankerkönig-Spritpreis-API
// Für eigenen Key bitte hier https://onboarding.tankerkoenig.de
// registrieren.
class _ApiKeyInterceptor extends Interceptor {
  final ApiKeyResolver _resolveApiKey;
  _ApiKeyInterceptor(this._resolveApiKey);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = _resolveApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      options.queryParameters['apikey'] = apiKey;
    }
    handler.next(options);
  }
}


import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../cache/cache_manager.dart';
import '../country/country_provider.dart';
import '../error_tracing/integrations/dio_trace_interceptor.dart';
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

@riverpod
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

  // Inject API key from user settings
  dio.interceptors.add(_ApiKeyInterceptor(ref));
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
@riverpod
StationService stationService(Ref ref) {
  final country = ref.watch(activeCountryProvider);
  return _resolveServiceForCountry(ref, country.code);
}

/// Get a station service for a specific country code.
/// Used by route search to query the correct API for each country
/// the route passes through (instead of using the profile's active country).
StationService stationServiceForCountry(Ref ref, String countryCode) =>
    _resolveServiceForCountry(ref, countryCode);

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

// Key für den Zugriff auf die freie Tankerkönig-Spritpreis-API
// Für eigenen Key bitte hier https://creativecommons.tankerkoenig.de
// registrieren.
class _ApiKeyInterceptor extends Interceptor {
  final Ref _ref;
  _ApiKeyInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final storage = _ref.read(storageRepositoryProvider);
    final apiKey = storage.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      options.queryParameters['apikey'] = apiKey;
    }
    handler.next(options);
  }
}


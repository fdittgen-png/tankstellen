import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../cache/cache_manager.dart';
import '../country/country_provider.dart';
import '../error_tracing/integrations/dio_trace_interceptor.dart';
import '../storage/storage_providers.dart';
import 'country_service_registry.dart';
import 'dio_factory.dart';
import 'geocoding_chain.dart';
import 'impl/demo_station_service.dart';
import 'impl/native_geocoding_provider.dart';
import 'impl/nominatim_geocoding_provider.dart';
import 'impl/tankerkoenig_station_service.dart';
import 'service_config.dart';
import 'service_result.dart';
import 'station_service.dart';
import 'station_service_chain.dart';

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

/// Returns the appropriate station service based on the active country
/// and whether an API key is configured.
///
/// Uses [CountryServiceRegistry] to look up the correct service factory.
/// Countries that require an API key (e.g. DE) fall back to demo data
/// when no key is configured.
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

/// Shared resolution logic used by both [stationService] and
/// [stationServiceForCountry].
///
/// Germany is special-cased because its Dio instance requires the API key
/// interceptor from [tankerkoenigDioProvider]. All other countries use
/// [CountryServiceRegistry.buildService] directly.
StationService _resolveServiceForCountry(Ref ref, String countryCode) {
  final cache = ref.read(cacheManagerProvider);

  // Germany needs special handling: API key check + dedicated Dio instance
  if (countryCode == 'DE') {
    final storage = ref.read(storageRepositoryProvider);
    if (!storage.hasApiKey()) return DemoStationService(countryCode: 'DE');
    final dio = ref.read(tankerkoenigDioProvider);
    return StationServiceChain(
      TankerkoenigStationService(dio),
      cache,
      errorSource: ServiceSource.tankerkoenigApi,
      countryCode: 'DE',
    );
  }

  return CountryServiceRegistry.buildService(countryCode, ref, cache);
}

// ---------------------------------------------------------------------------
// Geocoding with fallback chain: native → Nominatim → cache
// ---------------------------------------------------------------------------

@riverpod
GeocodingChain geocodingChain(Ref ref) {
  final cache = ref.watch(cacheManagerProvider);
  final country = ref.watch(activeCountryProvider);
  return GeocodingChain(
    [
      NativeGeocodingProvider(countryName: country.name), // Android/iOS only
      NominatimGeocodingProvider(countryCode: country.code), // All platforms
    ],
    cache,
    countryCode: country.code,
  );
}

// ---------------------------------------------------------------------------
// Interceptors (moved from dio_client.dart, now private to this file)
// ---------------------------------------------------------------------------

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


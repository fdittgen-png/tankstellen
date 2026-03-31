import 'dart:math';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../cache/cache_manager.dart';
import '../country/country_provider.dart';
import '../error_tracing/integrations/dio_trace_interceptor.dart';
import '../storage/hive_storage.dart';
import 'geocoding_chain.dart';
import 'impl/demo_station_service.dart';
import 'impl/argentina_station_service.dart';
import 'impl/denmark_station_service.dart';
import 'impl/econtrol_station_service.dart';
import 'impl/mise_station_service.dart';
import 'impl/miteco_station_service.dart';
import 'impl/native_geocoding_provider.dart';
import 'impl/prix_carburants_station_service.dart';
import 'impl/nominatim_geocoding_provider.dart';
import 'impl/osm_brand_enricher.dart';
import 'impl/portugal_station_service.dart';
import 'impl/uk_station_service.dart';
import 'impl/australia_station_service.dart';
import 'impl/mexico_station_service.dart';
import 'impl/tankerkoenig_station_service.dart';
import 'service_config.dart';
import 'service_result.dart';
import 'station_service.dart';
import 'station_service_chain.dart';

part 'service_providers.g.dart';

// ---------------------------------------------------------------------------
// Dio instance for Tankerkoenig (with API key + rate limit interceptors)
// ---------------------------------------------------------------------------

@riverpod
Dio tankerkoenigDio(Ref ref) {
  final config = ServiceConfigs.tankerkoenig;
  final dio = Dio(BaseOptions(
    baseUrl: config.baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    headers: config.headers,
  ));

  // Inject API key from user settings
  dio.interceptors.add(_ApiKeyInterceptor(ref));
  // Stagger requests to avoid thundering herd
  dio.interceptors.add(_RateLimitInterceptor());
  // Record HTTP errors in trace log
  dio.interceptors.add(DioTraceInterceptor(ref));

  return dio;
}

// ---------------------------------------------------------------------------
// Station service with full fallback chain
// ---------------------------------------------------------------------------

/// Returns the appropriate station service based on whether an API key
/// is configured. With key: Tankerkoenig with full fallback chain.
/// Without key: demo data so the app works immediately.
@riverpod
StationService stationService(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  final country = ref.watch(activeCountryProvider);
  final cache = ref.watch(cacheManagerProvider);

  // Germany requires API key
  if (country.code == 'DE') {
    if (!storage.hasApiKey()) return DemoStationService(countryCode: 'DE');
    final dio = ref.watch(tankerkoenigDioProvider);
    return StationServiceChain(
      TankerkoenigStationService(dio),
      cache,
      errorSource: ServiceSource.tankerkoenigApi,
      countryCode: 'DE',
    );
  }

  // Registry-based dispatch for all other countries
  final factory = _countryServiceFactories[country.code];
  if (factory != null) return factory(ref, cache);

  return DemoStationService(countryCode: country.code);
}

final _countryServiceFactories = <String, StationService Function(Ref, CacheManager)>{
  'FR': (ref, cache) {
    final enricher = ref.watch(osmBrandEnricherProvider);
    return StationServiceChain(
      PrixCarburantsStationService(enricher: enricher),
      cache,
      errorSource: ServiceSource.prixCarburantsApi,
      countryCode: 'FR',
    );
  },
  'AT': (ref, cache) => StationServiceChain(
    EControlStationService(), cache,
    errorSource: ServiceSource.eControlApi, countryCode: 'AT',
  ),
  'ES': (ref, cache) => StationServiceChain(
    MitecoStationService(), cache,
    errorSource: ServiceSource.mitecoApi, countryCode: 'ES',
  ),
  'IT': (ref, cache) => StationServiceChain(
    MiseStationService(), cache,
    errorSource: ServiceSource.miseApi, countryCode: 'IT',
  ),
  'DK': (ref, cache) => StationServiceChain(
    DenmarkStationService(), cache,
    errorSource: ServiceSource.denmarkApi, countryCode: 'DK',
  ),
  'AR': (ref, cache) => StationServiceChain(
    ArgentinaStationService(), cache,
    errorSource: ServiceSource.argentinaApi, countryCode: 'AR',
  ),
  'PT': (ref, cache) => StationServiceChain(
    PortugalStationService(), cache,
    errorSource: ServiceSource.portugalApi, countryCode: 'PT',
  ),
  'GB': (ref, cache) => StationServiceChain(
    UkStationService(), cache,
    errorSource: ServiceSource.ukApi, countryCode: 'GB',
  ),
  'AU': (ref, cache) => StationServiceChain(
    AustraliaStationService(), cache,
    errorSource: ServiceSource.australiaApi, countryCode: 'AU',
  ),
  'MX': (ref, cache) => StationServiceChain(
    MexicoStationService(), cache,
    errorSource: ServiceSource.mexicoApi, countryCode: 'MX',
  ),
};

/// Get a station service for a specific country code.
/// Used by route search to query the correct API for each country
/// the route passes through (instead of using the profile's active country).
StationService stationServiceForCountry(Ref ref, String countryCode) {
  final cache = ref.read(cacheManagerProvider);

  if (countryCode == 'DE') {
    final storage = ref.read(hiveStorageProvider);
    if (!storage.hasApiKey()) return DemoStationService(countryCode: 'DE');
    final dio = ref.read(tankerkoenigDioProvider);
    return StationServiceChain(
      TankerkoenigStationService(dio), cache,
      errorSource: ServiceSource.tankerkoenigApi, countryCode: 'DE',
    );
  }

  final factory = _countryServiceFactories[countryCode];
  if (factory != null) return factory(ref, cache);
  return DemoStationService(countryCode: countryCode);
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
    final storage = _ref.read(hiveStorageProvider);
    final apiKey = storage.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      options.queryParameters['apikey'] = apiKey;
    }
    handler.next(options);
  }
}

class _RateLimitInterceptor extends Interceptor {
  static final _random = Random();
  DateTime? _lastRequest;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(
          Duration(milliseconds: 500 + _random.nextInt(2500)),
        );
      }
    }
    _lastRequest = DateTime.now();
    handler.next(options);
  }
}

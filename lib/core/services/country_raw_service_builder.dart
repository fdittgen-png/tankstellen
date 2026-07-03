// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../features/station_services/argentina/argentina_station_service.dart';
import '../../features/station_services/australia/australia_station_service.dart';
import '../../features/station_services/austria/econtrol_station_service.dart';
import '../../features/station_services/chile/chile_station_service.dart';
import '../../features/station_services/denmark/denmark_station_service.dart';
import '../../features/station_services/france/prix_carburants_flux_station_service.dart';
import '../../features/station_services/france/prix_carburants_station_service.dart';
import '../../features/station_services/germany/tankerkoenig_station_service.dart';
import '../../features/station_services/greece/greece_station_service.dart';
import '../../features/station_services/italy/mise_station_service.dart';
import '../../features/station_services/luxembourg/luxembourg_station_service.dart';
import '../../features/station_services/mexico/mexico_station_service.dart';
import '../../features/station_services/portugal/portugal_station_service.dart';
import '../../features/station_services/romania/romania_station_service.dart';
import '../../features/station_services/slovenia/slovenia_station_service.dart';
import '../../features/station_services/south_korea/south_korea_station_service.dart';
import '../../features/station_services/spain/miteco_station_service.dart';
import '../../features/station_services/uk/uk_service_builder.dart';
import '../cache/cache_manager.dart';
import '../data/storage_repository.dart';
import 'bulk_migration_flags.dart';
import 'impl/demo_station_service.dart';
import 'impl/osm_brand_enricher.dart';
import 'station_service.dart';

/// The dependencies every per-country raw [StationService] can need,
/// resolved **once** by whoever builds the service (#2861).
///
/// This is the seam that makes country-service construction Riverpod-free:
/// the foreground reads each field from a `Ref`, the WorkManager / BGTask
/// background isolate constructs them directly from the isolate's
/// [HiveStorage], but the per-country wiring in [buildRawCountryService]
/// is *byte-identical* for both — there is one construction path.
///
///  - [storage] backs the API-key gate (DE/KR/CL), the [OsmBrandEnricher]
///    (FR legacy), and is the [CacheStorage] the bulk datasets persist to.
///  - [cache] is the shared [CacheStrategy] the bulk-dataset services
///    (ES/IT/AR/DK + the flag-gated FR/GB bulk paths) read-through.
///  - [tankerkoenigDio] is the rate-limited, API-key-injecting Dio the DE
///    Tankerkönig service talks through. Background callers build a plain
///    rate-limited Dio (the key is sent per-request); the foreground hands
///    the interceptor-wired `tankerkoenigDioProvider` instance.
class CountryServiceDependencies {
  const CountryServiceDependencies({
    required this.storage,
    required this.cache,
    required this.tankerkoenigDio,
  });

  /// Storage repository (favorites, settings, API keys, cache).
  final StorageRepository storage;

  /// Shared cache layer the bulk-dataset services persist through.
  final CacheStrategy cache;

  /// Dio for the DE Tankerkönig service. Only the DE branch reads it; other
  /// countries build their own Dio internally, so it is allowed to be null
  /// for non-DE construction.
  final Dio? tankerkoenigDio;
}

/// Builds the **raw** (un-chained) [StationService] for [countryCode] from
/// explicit [deps] — no Riverpod `Ref`, so the same wiring runs in the
/// WorkManager / BGAppRefresh background isolate that has no provider scope
/// (#2861).
///
/// This is the single source of truth for per-country service construction.
/// `CountryServiceRegistry`'s foreground `createService(Ref)` factories read
/// their dependencies from the `Ref` and delegate here, so the foreground
/// behaviour is unchanged — every country-service / chain / search test stays
/// green — while the background isolate reuses the identical wiring.
///
/// Returns [DemoStationService] for the API-key-gated countries (DE, KR, CL)
/// when no key is configured, exactly as the foreground factories did, so a
/// keyless user still sees realistic demo data.
StationService buildRawCountryService(
  String countryCode,
  CountryServiceDependencies deps,
) {
  switch (countryCode) {
    case 'DE':
      if (!deps.storage.hasApiKey()) {
        return DemoStationService(countryCode: 'DE');
      }
      final dio = deps.tankerkoenigDio;
      if (dio == null) {
        // Defensive: a DE caller must supply the Tankerkönig Dio. Without it
        // we cannot talk to the API, so fall back to demo rather than throw
        // inside an OS-spawned isolate.
        return DemoStationService(countryCode: 'DE');
      }
      return TankerkoenigStationService(dio);
    case 'FR':
      // #2277 staged rollout — bulk *flux instantané* when flagged, else the
      // legacy per-search OSM-enriched service.
      if (BulkMigrationFlags.frFluxBulk) {
        return PrixCarburantsFluxStationService(cache: deps.cache);
      }
      return PrixCarburantsStationService(
        enricher: OsmBrandEnricher(deps.storage),
      );
    case 'AT':
      return EControlStationService();
    case 'ES':
      return MitecoStationService(cache: deps.cache);
    case 'IT':
      return MiseStationService(cache: deps.cache);
    case 'DK':
      return DenmarkStationService(cache: deps.cache);
    case 'AR':
      return ArgentinaStationService(cache: deps.cache);
    case 'PT':
      return PortugalStationService();
    case 'GB':
      // #3190 — statutory Fuel Finder API as PRIMARY once OAuth2 credentials
      // are configured (Settings → API key, packed "client_id:client_secret"
      // — the same single per-country key slot DE/KR/CL read), legacy
      // retailer fan-out demoted to the in-service fallback; keyless
      // installs keep the legacy / #2277 flag-gated behaviour unchanged.
      // Composition lives feature-side in buildGbStationService (#3132
      // boundary ratchet: one core→feature import instead of five).
      return buildGbStationService(
        apiKey: deps.storage.getApiKey(),
        cache: deps.cache,
      );
    case 'AU':
      return const AustraliaStationService();
    case 'MX':
      return MexicoStationService(cache: deps.cache);
    case 'LU':
      return LuxembourgStationService();
    case 'SI':
      return SloveniaStationService();
    case 'KR':
      final apiKey = deps.storage.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return DemoStationService(countryCode: 'KR');
      }
      return SouthKoreaStationService(apiKey: apiKey);
    case 'CL':
      final apiKey = deps.storage.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return DemoStationService(countryCode: 'CL');
      }
      return ChileStationService(apiKey: apiKey);
    case 'GR':
      return GreeceStationService();
    case 'RO':
      return RomaniaStationService();
    default:
      return DemoStationService(countryCode: countryCode);
  }
}

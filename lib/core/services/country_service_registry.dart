import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/cache_manager.dart';
import '../country/country_config.dart';
import '../storage/storage_providers.dart';
import 'impl/argentina_station_service.dart';
import 'impl/australia_station_service.dart';
import 'impl/demo_station_service.dart';
import 'impl/denmark_station_service.dart';
import 'impl/econtrol_station_service.dart';
import 'impl/luxembourg_station_service.dart';
import 'impl/mexico_station_service.dart';
import 'impl/mise_station_service.dart';
import 'impl/miteco_station_service.dart';
import 'impl/osm_brand_enricher.dart';
import 'impl/portugal_station_service.dart';
import 'impl/prix_carburants_station_service.dart';
import 'impl/slovenia_station_service.dart';
import 'impl/tankerkoenig_station_service.dart';
import 'impl/uk_station_service.dart';
import 'service_providers.dart';
import 'service_result.dart';
import 'station_service.dart';
import 'station_service_chain.dart';

/// A single entry in the country service registry.
///
/// Encapsulates everything needed to create a [StationService] for one country:
/// the country code, the [ServiceSource] for error reporting, and a factory
/// that builds the raw (unwrapped) service instance.
///
/// The factory receives a [Ref] for dependency injection (e.g. Dio, enrichers)
/// and returns a raw [StationService] which will be wrapped in a
/// [StationServiceChain] by the registry.
class CountryServiceEntry {
  /// ISO 3166-1 alpha-2 country code (e.g. 'DE', 'FR').
  final String countryCode;

  /// The [ServiceSource] used for error attribution in the fallback chain.
  final ServiceSource errorSource;

  /// Whether this country requires a user-provided API key.
  final bool requiresApiKey;

  /// Factory that creates the raw [StationService] for this country.
  /// Receives a [Ref] for dependency injection.
  final StationService Function(Ref ref) createService;

  const CountryServiceEntry({
    required this.countryCode,
    required this.errorSource,
    this.requiresApiKey = false,
    required this.createService,
  });
}

/// Central registry of all country-specific station services.
///
/// This is the **single source of truth** for which countries have API
/// implementations. Adding a new country requires exactly one change:
/// add a [CountryServiceEntry] to [entries].
///
/// The registry provides compile-time safety through [assertAllCountriesRegistered],
/// which is called at app startup in debug mode to verify every country in
/// [Countries.all] has a corresponding entry.
class CountryServiceRegistry {
  CountryServiceRegistry._();

  /// All registered country service entries.
  ///
  /// To add a new country:
  /// 1. Create the service in `lib/core/services/impl/`
  /// 2. Add a [ServiceSource] variant in `service_result.dart`
  /// 3. Add a [CountryServiceEntry] here
  /// 4. Add a [CountryConfig] in `country_config.dart`
  ///
  /// The compile-time assertion ensures steps 3 and 4 stay in sync.
  static const List<CountryServiceEntry> entries = [
    CountryServiceEntry(
      countryCode: 'DE',
      errorSource: ServiceSource.tankerkoenigApi,
      requiresApiKey: true,
      createService: _createTankerkoenig,
    ),
    CountryServiceEntry(
      countryCode: 'FR',
      errorSource: ServiceSource.prixCarburantsApi,
      createService: _createPrixCarburants,
    ),
    CountryServiceEntry(
      countryCode: 'AT',
      errorSource: ServiceSource.eControlApi,
      createService: _createEControl,
    ),
    CountryServiceEntry(
      countryCode: 'ES',
      errorSource: ServiceSource.mitecoApi,
      createService: _createMiteco,
    ),
    CountryServiceEntry(
      countryCode: 'IT',
      errorSource: ServiceSource.miseApi,
      createService: _createMise,
    ),
    CountryServiceEntry(
      countryCode: 'DK',
      errorSource: ServiceSource.denmarkApi,
      createService: _createDenmark,
    ),
    CountryServiceEntry(
      countryCode: 'AR',
      errorSource: ServiceSource.argentinaApi,
      createService: _createArgentina,
    ),
    CountryServiceEntry(
      countryCode: 'PT',
      errorSource: ServiceSource.portugalApi,
      createService: _createPortugal,
    ),
    CountryServiceEntry(
      countryCode: 'GB',
      errorSource: ServiceSource.ukApi,
      createService: _createUk,
    ),
    CountryServiceEntry(
      countryCode: 'AU',
      errorSource: ServiceSource.australiaApi,
      createService: _createAustralia,
    ),
    CountryServiceEntry(
      countryCode: 'MX',
      errorSource: ServiceSource.mexicoApi,
      createService: _createMexico,
    ),
    CountryServiceEntry(
      countryCode: 'LU',
      errorSource: ServiceSource.luxembourgApi,
      createService: _createLuxembourg,
    ),
    CountryServiceEntry(
      countryCode: 'SI',
      errorSource: ServiceSource.sloveniaApi,
      createService: _createSlovenia,
    ),
  ];

  /// Lookup map built once from [entries] for O(1) access.
  static final Map<String, CountryServiceEntry> _byCode = {
    for (final entry in entries) entry.countryCode: entry,
  };

  /// All registered country codes.
  static Set<String> get registeredCountryCodes => _byCode.keys.toSet();

  /// Get the registry entry for a country code, or null if not registered.
  static CountryServiceEntry? entryFor(String countryCode) =>
      _byCode[countryCode];

  /// Build a [StationService] for [countryCode], wrapped in [StationServiceChain].
  ///
  /// Returns [DemoStationService] if:
  /// - The country has no registered entry
  /// - The country requires an API key but none is configured
  ///   (checked by the caller in service_providers.dart)
  static StationService buildService(
    String countryCode,
    Ref ref,
    CacheStrategy cache,
  ) {
    final entry = _byCode[countryCode];
    if (entry == null) return DemoStationService(countryCode: countryCode);

    return StationServiceChain(
      entry.createService(ref),
      cache,
      errorSource: entry.errorSource,
      countryCode: countryCode,
    );
  }

  /// Asserts that every country in [Countries.all] has a registry entry.
  ///
  /// Called at app startup in debug mode. This catches drift between
  /// country_config.dart and the registry — if you add a country config
  /// but forget to register its service, this fails immediately.
  static void assertAllCountriesRegistered() {
    final registeredCodes = _byCode.keys.toSet();
    final configuredCodes = Countries.all.map((c) => c.code).toSet();

    final missing = configuredCodes.difference(registeredCodes);
    if (missing.isNotEmpty) {
      throw StateError(
        'CountryServiceRegistry: missing entries for countries: '
        '${missing.join(', ')}. '
        'Add a CountryServiceEntry for each in country_service_registry.dart.',
      );
    }

    final extra = registeredCodes.difference(configuredCodes);
    if (extra.isNotEmpty) {
      debugPrint(
        'CountryServiceRegistry: entries without CountryConfig: '
        '${extra.join(', ')}',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Factory functions for each country's raw service
// ---------------------------------------------------------------------------
// These are top-level functions (not closures) so they can be used in
// const CountryServiceEntry constructors.

/// Germany factory. Reads the API-key state from storage and either:
///  - returns [DemoStationService] when no key is present (so the user sees
///    realistic-looking data without configuring anything), or
///  - constructs the real [TankerkoenigStationService] backed by the
///    rate-limited Dio from [tankerkoenigDioProvider].
///
/// This used to live in `service_providers.dart` as a Germany special case;
/// pulling it into the registry restores the "single source of truth"
/// invariant the registry promises.
StationService _createTankerkoenig(Ref ref) {
  final storage = ref.read(storageRepositoryProvider);
  if (!storage.hasApiKey()) return DemoStationService(countryCode: 'DE');
  final dio = ref.read(tankerkoenigDioProvider);
  return TankerkoenigStationService(dio);
}

StationService _createPrixCarburants(Ref ref) {
  final enricher = ref.watch(osmBrandEnricherProvider);
  return PrixCarburantsStationService(enricher: enricher);
}

StationService _createEControl(Ref ref) => EControlStationService();
StationService _createMiteco(Ref ref) => MitecoStationService();
StationService _createMise(Ref ref) => MiseStationService();
StationService _createDenmark(Ref ref) => DenmarkStationService();
StationService _createArgentina(Ref ref) => ArgentinaStationService();
StationService _createPortugal(Ref ref) => PortugalStationService();
StationService _createUk(Ref ref) => UkStationService();
StationService _createAustralia(Ref ref) => const AustraliaStationService();
StationService _createMexico(Ref ref) => MexicoStationService();
StationService _createLuxembourg(Ref ref) => LuxembourgStationService();
StationService _createSlovenia(Ref ref) => SloveniaStationService();

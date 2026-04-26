import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/cache_manager.dart';
import '../country/country_bounding_box.dart';
import '../country/country_config.dart';
import '../storage/storage_providers.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import 'impl/argentina_station_service.dart';
import 'impl/australia_station_service.dart';
import 'impl/chile_station_service.dart';
import 'impl/demo_station_service.dart';
import 'impl/denmark_station_service.dart';
import 'impl/econtrol_station_service.dart';
import 'impl/greece_station_service.dart';
import 'impl/luxembourg_station_service.dart';
import 'impl/mexico_station_service.dart';
import 'impl/mise_station_service.dart';
import 'impl/miteco_station_service.dart';
import 'impl/osm_brand_enricher.dart';
import 'impl/portugal_station_service.dart';
import 'impl/prix_carburants_station_service.dart';
import 'impl/romania_station_service.dart';
import 'impl/slovenia_station_service.dart';
import 'impl/south_korea_station_service.dart';
import 'impl/tankerkoenig_station_service.dart';
import 'impl/uk_station_service.dart';
import 'service_providers.dart';
import 'service_result.dart';
import 'station_service.dart';
import 'station_service_chain.dart';

/// A single entry in the country service registry — the **single source of
/// truth** for everything we need to know about a supported country at the
/// service layer.
///
/// Encapsulates the country code, the [ServiceSource] used for error
/// attribution in the fallback chain, the geographic [boundingBox] used to
/// validate geocoded coordinates and infer the origin country of a station
/// (#516), the ordered list of [availableFuelTypes] the upstream API
/// publishes, the API-key requirement, and the factory that builds the raw
/// [StationService].
///
/// Adding a 12th country now requires:
///
/// 1. One new file: `lib/core/services/impl/<country>_station_service.dart`
/// 2. One [ServiceSource] enum value in `service_result.dart` (mechanical;
///    enums naturally cluster on append)
/// 3. One new entry appended to [CountryServiceRegistry.entries]
///
/// The country's [CountryConfig] (display name, flag, postal-code shape,
/// currency formatting, etc.) is intentionally kept separate in
/// `country_config.dart` because every UI surface depends on it; folding
/// it into the entry would push the diff past 70 files for no real
/// extensibility win. The registry composes the config by code, not by
/// reference, via [Countries.byCode].
class CountryServiceEntry {
  /// ISO 3166-1 alpha-2 country code (e.g. 'DE', 'FR').
  final String countryCode;

  /// The [ServiceSource] used for error attribution in the fallback chain.
  final ServiceSource errorSource;

  /// Geographic bounding box used to:
  ///
  ///  - Validate geocoded coordinates land inside the expected country
  ///    (`GeocodingChain`).
  ///  - Infer the origin country of a station from its lat/lng when the
  ///    station id has no country prefix (#516, `Countries.countryForStation`).
  ///
  /// Boxes intentionally include a 1-2 degree margin to account for
  /// overseas territories, islands, and border regions.
  final CountryBoundingBox boundingBox;

  /// Ordered list of fuel types this country's UI fuel-type selector
  /// shows (#1112). Order matters: the most common fuel sits first, and
  /// every list ends with `FuelType.electric` followed by `FuelType.all`
  /// (the search-time wildcard).
  final List<FuelType> availableFuelTypes;

  /// Whether this country requires a user-provided API key.
  final bool requiresApiKey;

  /// Factory that creates the raw [StationService] for this country.
  /// Receives a [Ref] for dependency injection.
  final StationService Function(Ref ref) createService;

  const CountryServiceEntry({
    required this.countryCode,
    required this.errorSource,
    required this.boundingBox,
    required this.availableFuelTypes,
    this.requiresApiKey = false,
    required this.createService,
  });
}

/// Default ordered fuel-type list returned for any country not present in
/// the registry. Mirrors the historical `default:` branch of the old
/// `fuelTypesForCountry` switch — the minimal set every petrol/diesel
/// station can be assumed to carry, plus EV and the "all" wildcard.
const List<FuelType> _defaultFuelTypes = [
  FuelType.e5,
  FuelType.e10,
  FuelType.diesel,
  FuelType.electric,
  FuelType.all,
];

/// Central registry of all country-specific station services.
///
/// This is the **single source of truth** for which countries have API
/// implementations. Adding a new country requires exactly one new file in
/// `lib/core/services/impl/` plus one [CountryServiceEntry] appended to
/// [entries].
///
/// The registry provides compile-time safety through [assertAllCountriesRegistered],
/// which is called at app startup in debug mode to verify every country in
/// [Countries.all] has a corresponding entry.
class CountryServiceRegistry {
  CountryServiceRegistry._();

  /// All registered country service entries.
  ///
  /// Ordering note: the list is ordered for the bounding-box lookup
  /// algorithm (see [_entryByLatLng] / [countryCodeFromLatLng]). Small
  /// / island / coastal countries come first so their tight boxes are
  /// not shadowed by larger neighbours whose generous boxes incidentally
  /// overlap them — e.g. `PT`'s tight Iberian box sits entirely inside
  /// `ES`'s generous box, so `PT` must be tested first. Cross-currency
  /// border cases (#516) drove the ordering decisions:
  ///
  /// - `PT` first → its tight box is entirely inside `ES`'s.
  /// - `GB` early → island, no continental overlap.
  /// - `DK` before `DE` → Copenhagen's lat sits inside DE's box.
  /// - `LU` before `FR` / `DE` → Luxembourg-Ville at (49.6, 6.1) sits
  ///   inside both.
  /// - `SI` before `AT` / `IT` → Ljubljana sits inside both.
  /// - `CL` before `AR` → Santiago sits inside AR's generous box.
  /// - Continental EU countries last so stations outside every tighter
  ///   box still get attributed to something European.
  static const List<CountryServiceEntry> entries = [
    // ── Tight-box / island first (avoid shadowing) ─────────────────────
    CountryServiceEntry(
      countryCode: 'PT',
      errorSource: ServiceSource.portugalApi,
      boundingBox: CountryBoundingBox(
        minLat: 32.0, maxLat: 42.5, minLng: -32.0, maxLng: -6.0,
      ),
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createPortugal,
    ),
    CountryServiceEntry(
      countryCode: 'GB',
      errorSource: ServiceSource.ukApi,
      boundingBox: CountryBoundingBox(
        minLat: 49.5, maxLat: 61.0, minLng: -9.0, maxLng: 2.0,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createUk,
    ),
    CountryServiceEntry(
      countryCode: 'DK',
      errorSource: ServiceSource.denmarkApi,
      boundingBox: CountryBoundingBox(
        minLat: 54.0, maxLat: 58.0, minLng: 7.5, maxLng: 15.5,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createDenmark,
    ),
    CountryServiceEntry(
      countryCode: 'LU',
      errorSource: ServiceSource.luxembourgApi,
      // Tight box — LU is ~82 km north-south, ~57 km east-west; modest
      // margin so BE/FR/DE neighbours don't bleed into LU matches.
      boundingBox: CountryBoundingBox(
        minLat: 49.4, maxLat: 50.25, minLng: 5.7, maxLng: 6.55,
      ),
      // Luxembourg regulated prices (#574): Sans Plomb 95 (E5/E10),
      // Sans Plomb 98, Diesel, LPG.
      availableFuelTypes: [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createLuxembourg,
    ),
    CountryServiceEntry(
      countryCode: 'SI',
      errorSource: ServiceSource.sloveniaApi,
      // Tight box — Slovenia surrounded by IT / AT / HR; over-generous
      // margin would shadow them. See #575.
      boundingBox: CountryBoundingBox(
        minLat: 45.3, maxLat: 47.0, minLng: 13.3, maxLng: 16.7,
      ),
      // Slovenia (#575): NMB-95 (e5), NMB-100 (e98), Dizel, Dizel
      // Premium, LPG.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.electric,
        FuelType.all,
      ],
      createService: _createSlovenia,
    ),
    // ── Continental EU (test order matters for shadow neighbours) ─────
    CountryServiceEntry(
      countryCode: 'AT',
      errorSource: ServiceSource.eControlApi,
      boundingBox: CountryBoundingBox(
        minLat: 46.0, maxLat: 49.5, minLng: 9.0, maxLng: 17.5,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createEControl,
    ),
    CountryServiceEntry(
      countryCode: 'FR',
      errorSource: ServiceSource.prixCarburantsApi,
      // France (mainland), excludes overseas territories.
      boundingBox: CountryBoundingBox(
        minLat: 41.0, maxLat: 51.5, minLng: -5.5, maxLng: 10.0,
      ),
      // FR: Prix Carburants — SP95-E10 first (most common), then
      // SP95 / SP98, Gazole, E85 (Bioéthanol), GPL.
      availableFuelTypes: [
        FuelType.e10, FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.e85, FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createPrixCarburants,
    ),
    CountryServiceEntry(
      countryCode: 'IT',
      errorSource: ServiceSource.miseApi,
      boundingBox: CountryBoundingBox(
        minLat: 35.0, maxLat: 47.5, minLng: 6.0, maxLng: 19.0,
      ),
      // IT: MIMIT (osservaprezzi) — Benzina, Gasolio, GPL, Metano (CNG).
      availableFuelTypes: [
        FuelType.e5, FuelType.diesel, FuelType.lpg, FuelType.cng,
        FuelType.electric, FuelType.all,
      ],
      createService: _createMise,
    ),
    CountryServiceEntry(
      countryCode: 'ES',
      errorSource: ServiceSource.mitecoApi,
      // Spain (mainland + Balearic + Canary).
      boundingBox: CountryBoundingBox(
        minLat: 27.0, maxLat: 44.0, minLng: -19.0, maxLng: 5.0,
      ),
      // ES: Geoportal Gasolineras — 95/98, Diésel A/A+, GLP.
      availableFuelTypes: [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.electric,
        FuelType.all,
      ],
      createService: _createMiteco,
    ),
    CountryServiceEntry(
      countryCode: 'DE',
      errorSource: ServiceSource.tankerkoenigApi,
      requiresApiKey: true,
      boundingBox: CountryBoundingBox(
        minLat: 47.0, maxLat: 55.5, minLng: 5.5, maxLng: 15.5,
      ),
      // DE: Tankerkönig publishes E5, E10, Diesel.
      availableFuelTypes: _defaultFuelTypes,
      createService: _createTankerkoenig,
    ),
    // ── Non-EU countries (no overlap concerns) ─────────────────────────
    CountryServiceEntry(
      countryCode: 'MX',
      errorSource: ServiceSource.mexicoApi,
      boundingBox: CountryBoundingBox(
        minLat: 14.0, maxLat: 33.0, minLng: -119.0, maxLng: -86.0,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createMexico,
    ),
    // CL before AR: Chile's narrow strip sits inside AR's generous
    // longitude range along the cordillera (#596).
    CountryServiceEntry(
      countryCode: 'CL',
      errorSource: ServiceSource.chileApi,
      requiresApiKey: true,
      boundingBox: CountryBoundingBox(
        minLat: -56.5, maxLat: -17.0, minLng: -77.0, maxLng: -66.0,
      ),
      // CL (#596): Gasolina 93/95 (e5), Gasolina 97 (e98), Diésel, LPG.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createChile,
    ),
    CountryServiceEntry(
      countryCode: 'AR',
      errorSource: ServiceSource.argentinaApi,
      boundingBox: CountryBoundingBox(
        minLat: -56.0, maxLat: -21.0, minLng: -74.0, maxLng: -53.0,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createArgentina,
    ),
    CountryServiceEntry(
      countryCode: 'AU',
      errorSource: ServiceSource.australiaApi,
      boundingBox: CountryBoundingBox(
        minLat: -44.0, maxLat: -9.5, minLng: 112.5, maxLng: 154.0,
      ),
      availableFuelTypes: _defaultFuelTypes,
      createService: _createAustralia,
    ),
    CountryServiceEntry(
      countryCode: 'KR',
      errorSource: ServiceSource.openinetApi,
      requiresApiKey: true,
      // South Korea mainland + Jeju. No overlap with any other
      // registered country. See #597.
      boundingBox: CountryBoundingBox(
        minLat: 33.0, maxLat: 39.0, minLng: 124.0, maxLng: 131.0,
      ),
      // KR (#597): Gasoline (e5), Premium Gasoline (e98), Diesel, LPG.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createSouthKorea,
    ),
    CountryServiceEntry(
      countryCode: 'GR',
      errorSource: ServiceSource.greeceApi,
      // Eastern edge deliberately pulled in from the geographic limit
      // (~29.6) so Istanbul (41.01, 28.98) is NOT falsely attributed
      // to GR. Kastellorizo is the only Greek territory lost. See #576.
      boundingBox: CountryBoundingBox(
        minLat: 34.5, maxLat: 41.8, minLng: 19.0, maxLng: 28.5,
      ),
      // GR (#576): Αμόλυβδη 95 (e5), Αμόλυβδη 100 (e98), Diesel, LPG.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      createService: _createGreece,
    ),
    CountryServiceEntry(
      countryCode: 'RO',
      errorSource: ServiceSource.romaniaApi,
      // No neighbour conflicts — HU, BG, UA, RS, MD are not in the
      // registry. See #577.
      boundingBox: CountryBoundingBox(
        minLat: 43.5, maxLat: 48.5, minLng: 20.0, maxLng: 29.8,
      ),
      // RO (#577): Benzină Standard (e5), Benzină Premium (e98),
      // Motorină Standard (diesel), Motorină Premium (diesel premium),
      // GPL (lpg).
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.electric,
        FuelType.all,
      ],
      createService: _createRomania,
    ),
  ];

  /// Lookup map built once from [entries] for O(1) access by code.
  static final Map<String, CountryServiceEntry> _byCode = {
    for (final entry in entries) entry.countryCode: entry,
  };

  /// All registered country codes.
  static Set<String> get registeredCountryCodes => _byCode.keys.toSet();

  /// Get the registry entry for a country code, or null if not registered.
  static CountryServiceEntry? entryFor(String countryCode) =>
      _byCode[countryCode];

  /// Returns the bounding box for [countryCode], or null when unregistered.
  static CountryBoundingBox? boundingBoxFor(String countryCode) =>
      _byCode[countryCode]?.boundingBox;

  /// Ordered list of fuel types for [countryCode], or the default minimal
  /// set when the code is unregistered. Mirrors the historical
  /// `fuelTypesForCountry` switch's `default:` branch.
  static List<FuelType> fuelTypesFor(String countryCode) =>
      _byCode[countryCode]?.availableFuelTypes ?? _defaultFuelTypes;

  /// Returns the entry whose bounding box contains the given point, or
  /// null when no box matches. Walks [entries] in declared order — the
  /// list is intentionally ordered so tighter boxes are tested before
  /// the larger boxes that incidentally overlap them.
  static CountryServiceEntry? entryByLatLng(double lat, double lng) {
    for (final entry in entries) {
      if (entry.boundingBox.contains(lat, lng)) return entry;
    }
    return null;
  }

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

/// South Korea factory (#597). Reads the OPINET developer API key from
/// storage via [storageRepositoryProvider]. When no key is present we
/// return [DemoStationService] so a Korean user still sees realistic
/// data until they enter their free KNOC-issued key in Settings →
/// API keys.
StationService _createSouthKorea(Ref ref) {
  final storage = ref.read(storageRepositoryProvider);
  final apiKey = storage.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    return DemoStationService(countryCode: 'KR');
  }
  return SouthKoreaStationService(apiKey: apiKey);
}

/// Chile factory (#596). Reads the CNE "Bencina en Línea" developer
/// API key from storage via [storageRepositoryProvider]. When no key
/// is present we return [DemoStationService] so a Chilean user still
/// sees realistic data until they register a free CNE key in
/// Settings → API keys.
StationService _createChile(Ref ref) {
  final storage = ref.read(storageRepositoryProvider);
  final apiKey = storage.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    return DemoStationService(countryCode: 'CL');
  }
  return ChileStationService(apiKey: apiKey);
}

/// Greece factory (#576). The Paratiritirio Timon feed is wrapped by
/// the community [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr)
/// FastAPI; it is free and open, so no API key is required. Users get
/// real prefecture-level data out-of-the-box.
StationService _createGreece(Ref ref) => GreeceStationService();

/// Romania factory (#577). *Monitorul Prețurilor la Carburanți*
/// (pretcarburant.ro) is the Competition Council + ANPC observatory,
/// government-mandated with 15-minute price updates. There is no
/// documented public API — the parser is fixture-driven so a URL
/// drift is a one-line fix. No key required.
StationService _createRomania(Ref ref) => RomaniaStationService();

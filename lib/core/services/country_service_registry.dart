// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../background/provider_request_budget.dart';
import '../cache/cache_manager.dart';
import '../country/country_bounding_box.dart';
import '../country/country_config.dart';
import '../data/storage_repository.dart';
import '../storage/storage_providers.dart';
import '../domain/fuel_type.dart';
import 'bulk_migration_flags.dart';
import 'country_raw_service_builder.dart';
import 'diagnostics/data_access_recorder.dart';
import 'diagnostics/data_access_recorder_provider.dart';
import 'fuel_service_policy.dart';
import 'impl/demo_station_service.dart';
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
/// 1. A new file under
///    `lib/features/station_services/<country>/<country>_station_service.dart`
/// 2. One [ServiceSource] enum value in `service_result.dart` (mechanical;
///    enums naturally cluster on append)
/// 3. One new entry appended to [CountryServiceRegistry.entries]
///
/// The raw [StationService] is no longer a per-entry factory field: the
/// per-country construction lives in the single, Riverpod-free
/// [buildRawCountryService] (`country_raw_service_builder.dart`) so the
/// foreground ([CountryServiceRegistry.buildService]) and the WorkManager /
/// BGAppRefresh background isolate
/// ([CountryServiceRegistry.buildBackgroundService]) share one construction
/// path. Both dispatch on [countryCode].
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

  /// Typed data-source policy (#2264) — the single source of truth for the
  /// cache TTLs and rate-limit interval the service layer reads. The
  /// [StationServiceChain] branches on [FuelServicePolicy.model] to decide
  /// whether to local-filter a persisted bulk dataset or keep a per-search-key
  /// TTL cache; the rate limiter reads [FuelServicePolicy.minInterval].
  final FuelServicePolicy policy;

  const CountryServiceEntry({
    required this.countryCode,
    required this.errorSource,
    required this.boundingBox,
    required this.availableFuelTypes,
    required this.policy,
    this.requiresApiKey = false,
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

// ---------------------------------------------------------------------------
// Per-service data-source policies (#2264)
// ---------------------------------------------------------------------------
// Seeded from the Epic #2249 per-service audit. Each [CountryServiceEntry]
// references exactly one of these; they are the single source of truth for
// the cache TTLs + rate-limit interval the chain and Dio layer read. Values
// are deliberately conservative — for bulk files the soft TTL is roughly the
// upstream publish cadence and the hard TTL is a multiple of it (offline
// grace), for polled APIs `searchResultTtl` matches how fast prices move and
// `minInterval` matches the published / inferred rate limit.

/// DE Tankerkönig — polled API, ~1 request/min published policy, prices on a
/// 5-minute cadence. (#2264)
const _dePolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 5),
  attribution: 'Tankerkönig',
  license: 'CC BY 4.0',
  sourceUrl: 'https://creativecommons.tankerkoenig.de/',
);

/// AT e-control — polled API; the Spritpreisrechner refreshes hourly, so a
/// 1–2 h search TTL and a gentle 1 h min-interval keep us inside policy.
const _atPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 2),
  attribution: 'E-Control (Spritpreisrechner)',
  license: 'CC BY 3.0 AT',
  sourceUrl: 'https://www.spritpreisrechner.at/',
);

/// MX CRE — polled-then-merged feed that updates several times daily; cache
/// the merged result 4 h and don't re-pull more often than that.
const _mxPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 4),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 4),
  attribution: 'Comisión Reguladora de Energía (CRE)',
  license: 'Libre Uso MX',
  sourceUrl: 'https://datos.gob.mx/busca/dataset/ubicacion-de-gasolineras-y-precios-comerciales-de-gasolina-y-diesel',
);

/// PT DGEG — polled API; the portal publishes daily, so a 12 h search TTL and
/// a 1 h min-interval are comfortable.
const _ptPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 12),
  attribution: 'DGEG (preçoscombustíveis)',
  license: 'Open data (DGEG)',
  sourceUrl: 'https://precoscombustiveis.dgeg.gov.pt/',
);

/// UK CMA Fuel Finder — LEGACY polled fan-out across retailer feeds published
/// daily under the CMA scheme; cache each search 6 h. Default until the bulk
/// migration (#2277) is validated on-device.
const _ukPolicyLegacy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'CMA Fuel Finder (retailer feeds)',
  license: 'Open Government Licence v3.0',
  sourceUrl: 'https://www.gov.uk/guidance/access-fuel-price-data',
);

/// UK CMA Fuel Finder — BULK consolidated twice-daily file (#2277): one
/// whole-country download per ~12 h publication cadence, persisted and
/// local-filtered. Soft TTL ≈ the publish cadence, hard TTL an offline-grace
/// multiple. Selected only when `BulkMigrationFlags.ukCmaBulk` is `true`.
const _ukPolicyBulk = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration(hours: 12),
  datasetTtlHard: Duration(hours: 48),
  searchResultTtl: Duration.zero,
  attribution: 'CMA Fuel Finder (consolidated)',
  license: 'Open Government Licence v3.0',
  sourceUrl: 'https://www.gov.uk/guidance/access-fuel-price-data',
);

/// Staged-rollout selection (#2277): legacy by default, bulk when flagged.
const _ukPolicy =
    BulkMigrationFlags.ukCmaBulk ? _ukPolicyBulk : _ukPolicyLegacy;

/// LU — government-regulated uniform prices, polled; a daily refresh is ample
/// since the price changes only by ministerial arrêté.
const _luPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 6),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 12),
  attribution: 'gouvernement.lu',
  license: 'CC0 1.0',
  sourceUrl: 'https://data.public.lu/fr/datasets/prix-des-carburants/',
);

/// SI goriva.si — polled API; daily-ish updates.
const _siPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'goriva.si / Ministrstvo za gospodarstvo',
  license: 'Open data (gov.si)',
  sourceUrl: 'https://goriva.si/',
);

/// KR OPINET — polled API; near-real-time prices, 5-minute search TTL.
const _krPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'OPINET (KNOC)',
  license: 'KOGL Type 1',
  sourceUrl: 'https://www.opinet.co.kr/',
);

/// CL CNE Bencina en Línea — polled API; daily-ish updates.
const _clPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'CNE (Comisión Nacional de Energía)',
  license: 'Datos Abiertos CL',
  sourceUrl: 'https://www.cne.cl/',
);

/// GR Paratiritirio Timon — polled API (community FastAPI wrapper); prefecture
/// observatory updates roughly daily.
const _grPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'Παρατηρητήριο Τιμών Υγρών Καυσίμων',
  license: 'Open data (data.gov.gr)',
  sourceUrl: 'https://paratiritirio.mindev.gov.gr/',
);

/// RO Monitorul Prețurilor — polled API; 15-minute upstream updates.
const _roPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 15),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'Consiliul Concurenței (Monitorul Prețurilor)',
  license: 'Open data (RO)',
  sourceUrl: 'https://www.monitorulpreturilor.info/',
);

/// AU FuelCheck — stub (#804); throws on every search. Policy still recorded
/// so the row exists once an endpoint lands; polled when it does.
const _auPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'NSW Government FuelCheck',
  license: 'CC BY 4.0',
  sourceUrl: 'https://www.fuelcheck.nsw.gov.au/',
);

/// ES MITECO — bulk national dataset (~12k stations) downloaded per province
/// and filtered locally; published daily.
const _esPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Geoportal Gasolineras (MITECO)',
  license: 'Open data (MITECO)',
  sourceUrl: 'https://geoportalgasolineras.es/',
);

/// IT MIMIT (osservaprezzi) — bulk CSV dataset published daily at 08:00.
const _itPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'MIMIT (osservaprezzi)',
  license: 'IODL 2.0',
  sourceUrl: 'https://carburanti.mise.gov.it/ospzSearch/',
);

/// AR Secretaría de Energía — bulk CSV dataset (Resolución 314/2016); a few
/// updates per day, large file.
const _arPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Secretaría de Energía (datos.energia.gob.ar)',
  license: 'Open data (AR)',
  sourceUrl: 'https://datos.energia.gob.ar/dataset/precios-en-surtidor',
);

/// DK — bulk national aggregate across OK / Shell / Q8 feeds, filtered
/// locally; refreshed a few times daily.
const _dkPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 15),
  datasetTtlSoft: Duration(hours: 2),
  datasetTtlHard: Duration(hours: 12),
  searchResultTtl: Duration.zero,
  attribution: 'OK / Shell / Q8 (DK)',
  license: 'Provider terms',
  sourceUrl: 'https://www.ok.dk/privat/produkter/benzinkort/aktuelle-braendstofpriser',
);

/// FR Prix Carburants — LEGACY polled/OSM-enriched per-search query against
/// data.economie.gouv.fr. Default until the bulk migration (#2277) is
/// validated on-device.
const _frPolicyLegacy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'Prix Carburants (data.economie.gouv.fr)',
  license: 'Licence Ouverte 2.0',
  sourceUrl: 'https://www.prix-carburants.gouv.fr/',
);

/// FR Prix Carburants — BULK *flux instantané* ZIP (#2277): one whole-country
/// download per ~10 min cadence, persisted and local-filtered (never poll
/// per-station). Soft TTL ≈ the 10-min flux cadence, hard TTL an offline-grace
/// multiple. Selected only when `BulkMigrationFlags.frFluxBulk` is `true`.
const _frPolicyBulk = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 10),
  datasetTtlSoft: Duration(minutes: 10),
  datasetTtlHard: Duration(hours: 6),
  searchResultTtl: Duration.zero,
  attribution: 'Prix Carburants (flux instantané)',
  license: 'Licence Ouverte 2.0',
  sourceUrl: 'https://www.prix-carburants.gouv.fr/',
);

/// Staged-rollout selection (#2277): legacy by default, bulk when flagged.
const _frPolicy =
    BulkMigrationFlags.frFluxBulk ? _frPolicyBulk : _frPolicyLegacy;

/// Central registry of all country-specific station services.
///
/// This is the **single source of truth** for which countries have API
/// implementations. Adding a new country requires exactly one new file
/// under `lib/features/station_services/<country>/` plus one
/// [CountryServiceEntry] appended to [entries].
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
      policy: _ptPolicy,
    ),
    CountryServiceEntry(
      countryCode: 'GB',
      errorSource: ServiceSource.ukApi,
      boundingBox: CountryBoundingBox(
        minLat: 49.5, maxLat: 61.0, minLng: -9.0, maxLng: 2.0,
      ),
      // GB (#2180): UkStationService parses the CMA feed into e5
      // (E5/unleaded), e10 (E10), e98 (super_unleaded), diesel
      // (B7/diesel). _defaultFuelTypes omitted e98, so super-unleaded
      // stations could not be searched — promote to the explicit set.
      availableFuelTypes: [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.electric, FuelType.all,
      ],
      policy: _ukPolicy,
    ),
    CountryServiceEntry(
      countryCode: 'DK',
      errorSource: ServiceSource.denmarkApi,
      boundingBox: CountryBoundingBox(
        minLat: 54.0, maxLat: 58.0, minLng: 7.5, maxLng: 15.5,
      ),
      // DK (#3198): the single 95-octane grade is e5 only (no published
      // E10); the #3187 exact-grade mapping emits Oktan 100 / V-Power →
      // e98 and V-Power Diesel → dieselPremium.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.electric, FuelType.all,
      ],
      policy: _dkPolicy,
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
      policy: _luPolicy,
    ),
    CountryServiceEntry(
      countryCode: 'SI',
      errorSource: ServiceSource.sloveniaApi,
      // Tight box — Slovenia surrounded by IT / AT / HR; over-generous
      // margin would shadow them. See #575.
      boundingBox: CountryBoundingBox(
        minLat: 45.3, maxLat: 47.0, minLng: 13.3, maxLng: 16.7,
      ),
      // Slovenia (#575/#3198): NMB-95 → e5 (single 95-octane grade — the
      // old e5→e10 mirror is gone, goriva.si publishes no E10),
      // NMB-100/98 → e98, Dizel → diesel, Dizel Premium → dieselPremium,
      // avtoplin-lpg → lpg, cng → cng.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.lpg, FuelType.cng,
        FuelType.electric, FuelType.all,
      ],
      policy: _siPolicy,
    ),
    // ── Continental EU (test order matters for shadow neighbours) ─────
    CountryServiceEntry(
      countryCode: 'AT',
      errorSource: ServiceSource.eControlApi,
      boundingBox: CountryBoundingBox(
        minLat: 46.0, maxLat: 49.5, minLng: 9.0, maxLng: 17.5,
      ),
      // AT (#3198): E-Control publishes exactly one petrol grade (SUP);
      // the default set advertised an E10 the feed never carries.
      availableFuelTypes: [
        FuelType.e5, FuelType.diesel, FuelType.electric, FuelType.all,
      ],
      policy: _atPolicy,
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
      policy: _frPolicy,
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
      policy: _itPolicy,
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
      policy: _esPolicy,
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
      policy: _dePolicy,
    ),
    // ── Non-EU countries (no overlap concerns) ─────────────────────────
    CountryServiceEntry(
      countryCode: 'MX',
      errorSource: ServiceSource.mexicoApi,
      boundingBox: CountryBoundingBox(
        minLat: 14.0, maxLat: 33.0, minLng: -119.0, maxLng: -86.0,
      ),
      // MX (#2704): CRE sells Regular (Magna, e5), Premium (91–92, e98) and
      // Diesel in MXN — premium maps to the high-octane e98 slot, NOT the
      // European e10 ethanol blend. The picker must offer what the parser
      // surfaces.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.electric, FuelType.all,
      ],
      policy: _mxPolicy,
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
      policy: _clPolicy,
    ),
    CountryServiceEntry(
      countryCode: 'AR',
      errorSource: ServiceSource.argentinaApi,
      boundingBox: CountryBoundingBox(
        minLat: -56.0, maxLat: -21.0, minLng: -74.0, maxLng: -53.0,
      ),
      // AR (#2180/#3198): ArgentinaStationService emits Nafta súper → e5
      // (no e10 — the feed publishes no E10 grade), Nafta premium → e98,
      // Gas oil → diesel, Gas oil premium → dieselPremium, GNC → cng.
      availableFuelTypes: [
        FuelType.e5, FuelType.e98, FuelType.diesel,
        FuelType.dieselPremium, FuelType.cng, FuelType.electric,
        FuelType.all,
      ],
      policy: _arPolicy,
    ),
    CountryServiceEntry(
      countryCode: 'AU',
      errorSource: ServiceSource.australiaApi,
      boundingBox: CountryBoundingBox(
        minLat: -44.0, maxLat: -9.5, minLng: 112.5, maxLng: 154.0,
      ),
      // AU (#2180): NSW FuelCheck publishes U91 → e5, U95 → e10, U98 →
      // e98, Diesel → diesel, LPG → lpg. AustraliaStationService is a
      // documented stub pending a working endpoint (#804), so there is no
      // live emission to converge on; this mirrors the config's
      // FuelCheck grade set instead of the unrelated _defaultFuelTypes
      // fallback, keeping the picker and selector in agreement.
      availableFuelTypes: [
        FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
        FuelType.lpg, FuelType.electric, FuelType.all,
      ],
      policy: _auPolicy,
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
      policy: _krPolicy,
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
      policy: _grPolicy,
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
      policy: _roPolicy,
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

  /// Returns the [FuelServicePolicy] for [countryCode], or null when
  /// unregistered (#2264).
  static FuelServicePolicy? policyFor(String countryCode) =>
      _byCode[countryCode]?.policy;

  /// Ordered list of fuel types for [countryCode], or the default minimal
  /// set when the code is unregistered. Mirrors the historical
  /// `fuelTypesForCountry` switch's `default:` branch.
  static List<FuelType> fuelTypesFor(String countryCode) =>
      _byCode[countryCode]?.availableFuelTypes ?? _defaultFuelTypes;

  /// Returns the entry whose bounding box contains the given point, or
  /// null when no box matches. Walks [entries] in declared order — the
  /// list is intentionally ordered so tighter boxes are tested before
  /// the larger boxes that incidentally overlap them.
  ///
  /// First-match: used for single-country attribution (#516) where one
  /// answer is wanted. For corridor detection — where a point inside a
  /// larger box that SHADOWS a smaller declared-later box must still
  /// surface the shadowed country — use [entriesByLatLng] (#2621).
  static CountryServiceEntry? entryByLatLng(double lat, double lng) {
    for (final entry in entriesByLatLng(lat, lng)) {
      return entry;
    }
    return null;
  }

  /// Every entry whose bounding box contains the given point, in declared
  /// order — NOT just the first match (#2621).
  ///
  /// Continental bounding boxes overlap: FR's box (lat 41.0–51.5,
  /// lng −5.5–10.0) geographically contains all of Catalonia, yet ES is
  /// declared later, so [entryByLatLng] resolves every Catalonian point to
  /// FR and never reaches ES. A Pézenas→Barcelona corridor then queried
  /// only FR and returned zero Spanish stations. Corridor detection unions
  /// these so the shadowed country (ES) is never dropped — over-collecting
  /// is safe because the route detour filter drops off-corridor stations.
  static Iterable<CountryServiceEntry> entriesByLatLng(
      double lat, double lng) sync* {
    for (final entry in entries) {
      if (entry.boundingBox.contains(lat, lng)) yield entry;
    }
  }

  /// Build a [StationService] for [countryCode], wrapped in
  /// [StationServiceChain] — the **foreground** path.
  ///
  /// Reads its dependencies (storage, the Tankerkönig Dio, the dev-only
  /// #2824 recorder) from the Riverpod [ref] and delegates the actual
  /// construction to [buildBackgroundService], so the foreground and the
  /// WorkManager / BGAppRefresh background isolate share one code path
  /// (#2861).
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
    return buildBackgroundService(
      countryCode,
      storage: ref.read(storageRepositoryProvider),
      cache: cache,
      tankerkoenigDio: countryCode == 'DE'
          ? ref.read(tankerkoenigDioProvider)
          : null,
      // #2824 — dev-only tracer (null in production); #2866 — shared per-
      // provider budget the foreground stamps so the BG scan won't re-poll.
      recorder: ref.read(dataAccessRecorderProvider),
      budget: ProviderRequestBudget(ref.read(storageRepositoryProvider)),
    );
  }

  /// Build a [StationService] for [countryCode] **without a Riverpod `Ref`**
  /// — the background-isolate construction path (#2861).
  ///
  /// The WorkManager / BGAppRefresh isolate has no provider scope, but the
  /// registry's lookups (entries / policies / bounding boxes) are static and
  /// isolate-safe; the only thing the foreground `Ref` provided was the set
  /// of resolved dependencies, which this method takes directly:
  ///
  ///  - [storage] — the isolate's [HiveStorage] (API-key gate, bulk-dataset
  ///    cache backing, OSM brand enricher).
  ///  - [cache] — a [CacheStrategy] (the isolate builds `CacheManager(storage)`).
  ///  - [tankerkoenigDio] — only the DE branch needs it; a background caller
  ///    passes a plain rate-limited Dio and sends the key per-request.
  ///  - [recorder] (#2824 tracer) + [budget] (#2866 shared per-provider gate
  ///    the chain stamps on a hit) — both threaded through; usually null.
  ///
  /// Builds the **same** [StationServiceChain] (same primary service, error
  /// source, policy) the foreground builds, via the single, Riverpod-free
  /// [buildRawCountryService]. Returns [DemoStationService] when the country
  /// has no registered entry.
  static StationService buildBackgroundService(
    String countryCode, {
    required StorageRepository storage,
    required CacheStrategy cache,
    Dio? tankerkoenigDio,
    DataAccessRecorder? recorder,
    ProviderRequestBudget? budget,
  }) {
    final entry = _byCode[countryCode];
    if (entry == null) return DemoStationService(countryCode: countryCode);

    recorder?.notePolicy(countryCode, entry.policy.minInterval);
    final raw = buildRawCountryService(
      countryCode,
      CountryServiceDependencies(
        storage: storage,
        cache: cache,
        tankerkoenigDio: tankerkoenigDio,
      ),
    );
    return StationServiceChain(
      raw,
      cache,
      errorSource: entry.errorSource,
      countryCode: countryCode,
      // #2264 — the chain branches on this to local-filter bulk datasets
      // (no per-key cache) vs keep the per-key TTL cache for polled APIs.
      policy: entry.policy,
      recorder: recorder,
      budget: budget,
    );
  }

  /// Derive the ISO country code an alert's **station id** belongs to
  /// (#2861). Neither [PriceAlert] nor any favorite stores a country, so we
  /// infer it lazily from the id's prefix (the #753 `de-`/`uk-`/… scheme).
  /// Returns null when the id carries no recognised prefix (e.g. a raw DE
  /// Tankerkönig UUID) — the caller can then fall back to the active country.
  static String? countryForStationId(String? stationId) =>
      Countries.countryCodeForStationId(stationId);

  /// Derive the ISO country code a **radius-alert centre** lies in (#2861)
  /// via the registry's bounding-box lookup. Returns null when the point is
  /// outside every registered box.
  static String? countryForLatLng(double lat, double lng) =>
      entryByLatLng(lat, lng)?.countryCode;

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


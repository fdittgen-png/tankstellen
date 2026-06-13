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
import 'country_raw_service_builder.dart';
import 'country_service_data.dart';
import 'country_service_entry.dart';
import 'diagnostics/data_access_recorder.dart';
import 'diagnostics/data_access_recorder_provider.dart';
import 'fuel_service_policy.dart';
import 'impl/demo_station_service.dart';
import 'service_providers.dart';
import 'station_service.dart';
import 'station_service_chain.dart';

// #3232 — [CountryServiceEntry] lives in its own file now; re-export it so the
// dozens of `import '.../country_service_registry.dart'` sites that reference
// the type keep resolving it unchanged.
export 'country_service_entry.dart';

/// Central registry of all country-specific station services.
///
/// This is the **single source of truth** for which countries have API
/// implementations. The data rows (per-service policies + the ordered
/// [CountryServiceEntry] list) live in `country_service_data.dart` (#3232);
/// this class holds only the **behaviour** — the lookups and the foreground /
/// background service builders. Adding a new country requires exactly one new
/// file under `lib/features/station_services/<country>/` plus one
/// [CountryServiceEntry] appended to `kCountryServiceEntries`.
///
/// The registry provides compile-time safety through [assertAllCountriesRegistered],
/// which is called at app startup in debug mode to verify every country in
/// [Countries.all] has a corresponding entry.
class CountryServiceRegistry {
  CountryServiceRegistry._();

  /// All registered country service entries.
  ///
  /// Aliases the [kCountryServiceEntries] data list (#3232) so existing
  /// `CountryServiceRegistry.entries` call sites are unchanged. The list is
  /// ordered for the bounding-box lookup algorithm (see [entryByLatLng] /
  /// [entriesByLatLng]) — tighter boxes first so they aren't shadowed by larger
  /// neighbours; see the ordering note on [kCountryServiceEntries].
  static const List<CountryServiceEntry> entries = kCountryServiceEntries;

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
      _byCode[countryCode]?.availableFuelTypes ?? kDefaultFuelTypes;

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
        'Add a CountryServiceEntry for each in country_service_data.dart.',
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

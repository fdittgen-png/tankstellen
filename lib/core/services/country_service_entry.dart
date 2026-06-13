// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../country/country_bounding_box.dart';
import '../domain/fuel_type.dart';
import 'fuel_service_policy.dart';
import 'service_result.dart';

/// A single entry in the country service registry — the **single source of
/// truth** for everything we need to know about a supported country at the
/// service layer.
///
/// Encapsulates the country code, the [ServiceSource] used for error
/// attribution in the fallback chain, the geographic [boundingBox] used to
/// validate geocoded coordinates and infer the origin country of a station
/// (#516), the ordered list of [availableFuelTypes] the upstream API
/// publishes, the API-key requirement, and the data-source [policy].
///
/// Adding a 12th country now requires:
///
/// 1. A new file under
///    `lib/features/station_services/<country>/<country>_station_service.dart`
/// 2. One [ServiceSource] enum value in `service_result.dart` (mechanical;
///    enums naturally cluster on append)
/// 3. One new entry appended to `kCountryServiceEntries`
///    (`country_service_data.dart`)
///
/// The raw `StationService` is no longer a per-entry factory field: the
/// per-country construction lives in the single, Riverpod-free
/// `buildRawCountryService` (`country_raw_service_builder.dart`) so the
/// foreground (`CountryServiceRegistry.buildService`) and the WorkManager /
/// BGAppRefresh background isolate (`CountryServiceRegistry.buildBackgroundService`)
/// share one construction path. Both dispatch on [countryCode].
///
/// The country's `CountryConfig` (display name, flag, postal-code shape,
/// currency formatting, etc.) is intentionally kept separate in
/// `country_config.dart` because every UI surface depends on it; folding
/// it into the entry would push the diff past 70 files for no real
/// extensibility win. The registry composes the config by code, not by
/// reference, via `Countries.byCode`.
///
/// #3232 — extracted out of `country_service_registry.dart` so the registry
/// file holds only behaviour (lookups + service builders) and the country
/// data rows live in `country_service_data.dart`. Re-exported by the registry
/// for backward compatibility, so existing
/// `import '.../country_service_registry.dart'` sites keep resolving
/// [CountryServiceEntry] unchanged.
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
  /// `StationServiceChain` branches on [FuelServicePolicy.model] to decide
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

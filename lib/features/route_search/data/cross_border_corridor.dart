// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_config.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/station_extensions.dart';
import '../../profile/data/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/search_result_item.dart';
import '../../search/domain/entities/station.dart';
import '../domain/entities/route_info.dart';
import '../domain/route_search_strategy.dart';
import 'strategies/route_geometry.dart';

/// Cross-border corridor station search (#2595).
///
/// A route that crosses a border (Pézenas FR → Barcelona ES) must query
/// the open-data source of EVERY country the corridor passes through for
/// which a profile (and thus a configured data source) exists — and price
/// each leg for that country's profile fuel. Previously the search
/// resolved the country via a NETWORK geocode that, on null/timeout, fell
/// back to the active profile's country, so the whole Spanish leg silently
/// hit FR Prix-Carburants with the single active fuel (E85) and came back
/// empty.
///
/// These helpers are the country-detection + per-country (service, fuel)
/// resolution + the per-point query function. They are top-level (taking a
/// [Ref]) so `RouteSearchState` stays a thin orchestrator and this cohesive
/// cross-border logic — plus its unit tests — lives in one place.

/// A corridor country's resolved station service paired with the fuel its
/// leg should be queried + priced for.
typedef CountrySource = ({StationService service, FuelType fuel});

/// Profile fuel keyed by upper-cased country code.
///
/// `{ for p in allProfiles if p.countryCode != null :
///    p.countryCode.toUpperCase(): p.preferredFuelType }`. A later profile
/// for the same country wins — "the most recently configured profile for
/// that country" without an extra heuristic.
Map<String, FuelType> profileFuelByCountry(Ref ref) {
  final out = <String, FuelType>{};
  for (final p in ref.read(allProfilesProvider)) {
    final code = p.countryCode;
    if (code != null) out[code.toUpperCase()] = p.preferredFuelType;
  }
  return out;
}

/// Pre-resolve, OFFLINE, the `(service, fuel)` for every country the
/// corridor crosses **and the user has a profile for**.
///
/// #2741 — the maintainer's binding rule: query a country's data source IF AND
/// ONLY IF (a) the route GENUINELY enters it (the [corridorCountries] geometric
/// gate) AND (b) the user has a profile for it. So an FR-only profile yields
/// French data only — always — even on a route that dips into Spain's
/// over-generous border box; a cross-border FR→ES corridor shows BOTH only when
/// profiles for both exist. The country set is therefore [corridorCountries]
/// (genuine-entry gated) INTERSECTED with the profile countries; the old
/// `countriesTouchingRouteExtent` belt-and-braces union is dropped (its plain
/// whole-route-AABB test re-over-collected near-border neighbours). A safety
/// net re-adds the active profile's own country so the route's home country is
/// never dropped on a degenerate all-overlap geometry.
///
/// The set is then intersected with the registered, key-satisfied services: a
/// country is SKIPPED when unregistered or when it needs an unconfigured API
/// key (the DE / CL / KR demo guard). Per-country fuel is the profile's
/// `preferredFuelType` from [profileFuels] (the E10 fall-back is now unreachable
/// — every code is a profile country — but kept for safety).
Map<String, CountrySource> buildCorridorServiceMap(
  Ref ref,
  RouteInfo route,
  Map<String, FuelType> profileFuels,
) {
  final hasKey = ref.read(storageRepositoryProvider).hasApiKey();
  // #2741 — the maintainer's profile rule: query a country only when the user
  // has a profile for it. Genuine geographic entry alone is not enough.
  final profileCountries =
      profileFuels.keys.map((c) => c.toUpperCase()).toSet();
  final codes = corridorCountries(route) // genuine-entry gated (#2741)
      .map((c) => c.toUpperCase())
      .where(profileCountries.contains)
      .toSet();
  // Safety net — never drop the route's OWN/active country when it is a
  // profile country (it is already in `corridorCountries` when genuinely on
  // the route; this guards a degenerate all-overlap geometry where the gate
  // credits nothing). Best-effort: an unresolved active profile (e.g. a
  // storage-less harness) just skips the net — the gate + profile intersection
  // already cover every real route.
  final activeCode = _activeCountryCode(ref);
  if (activeCode != null && profileCountries.contains(activeCode)) {
    codes.add(activeCode);
  }
  final map = <String, CountrySource>{};
  for (final code in codes) {
    final entry = CountryServiceRegistry.entryFor(code);
    if (entry == null) continue; // unregistered → no real data source.
    if (entry.requiresApiKey && !hasKey) continue; // demo guard (#2595).
    map[code] = (
      service: stationServiceForCountry(ref, code),
      fuel: profileFuels[code] ?? FuelType.e10,
    );
  }
  debugPrint('RouteSearch: corridor services = '
      '${map.entries.map((e) => '${e.key}:${e.value.fuel.apiValue}').join(', ')}');
  return map;
}

/// The active profile's upper-cased country code, or `null` when absent /
/// unresolvable (#2741 safety-net read). Guarded: a storage-less harness leaves
/// [activeProfileProvider] in an error state, and the corridor build must never
/// abort on it — the gate + profile intersection already give the right set.
String? _activeCountryCode(Ref ref) {
  try {
    return ref.read(activeProfileProvider)?.countryCode?.toUpperCase();
  } on Object {
    return null;
  }
}

/// Build the per-point query function for a cross-border route.
///
/// For each sample point it queries EVERY corridor-country service in
/// [corridorMap] — each with THAT country's profile fuel — and merges the
/// responses. Querying all corridor services (rather than only the one the
/// point's bbox resolves to) is deliberate: the FR and ES bounding boxes
/// overlap heavily along the Pyrenees, so a pure per-point bbox switch
/// still mis-attributes the whole Catalonia leg to FR.
/// `UniformSearchStrategy._runFilterAndSort` then drops every station whose
/// min-distance-to-polyline exceeds the detour limit, so a FR station
/// fetched near Barcelona is filtered out while the local ES stations
/// survive — robustly correct at any border.
///
/// Each country's slice is reduced to the top [topNPerSamplePoint] by
/// [criterion] using THAT country's fuel, so [BatchQueryHelper.queryAll]'s
/// single-fuel reduce downstream is a harmless identity (already ranked and
/// bounded). When [corridorMap] is empty (an entirely mid-sea route, or no
/// profile-backed corridor country) the active profile's service + the
/// incoming [fuelType] are used as a fallback so a single-country route is
/// unaffected.
///
/// Each per-country `searchStations` is wrapped in a try/catch (#2621): one
/// country's outage / throw must NOT abort the whole route — the other legs
/// still resolve. #2703 — a recoverable per-leg failure (the overall corridor
/// still returns results) records a diagnostic [BreadcrumbCollector]
/// breadcrumb rather than a top-level ERROR trace, so a flaky feed (the
/// southern-France UK-feed timeouts) no longer spams the error log; the
/// orchestrator raises ONE aggregate ERROR only when the merged result is
/// empty.
StationQueryFunction buildCorridorQueryFunction(
  Ref ref,
  FuelType fuelType, {
  required Map<String, CountrySource> corridorMap,
  required RouteSearchCriterion criterion,
  required int topNPerSamplePoint,
}) {
  // Only fall back to the active-profile service when the corridor map is
  // empty — reading it eagerly would needlessly build the active country's
  // service on every normal cross-border search.
  final sources = corridorMap.isEmpty
      ? <String, CountrySource>{
          '*': (service: ref.read(stationServiceProvider), fuel: fuelType)
        }
      : corridorMap;

  return ({
    required double lat,
    required double lng,
    required double radiusKm,
    required FuelType fuelType,
  }) async {
    final merged = <SearchResultItem>[];
    for (final MapEntry(key: countryCode, value: source) in sources.entries) {
      final params = SearchParams(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        fuelType: source.fuel,
        sortBy: SortBy.price,
      );
      final List<SearchResultItem> raw;
      try {
        final result = await source.service.searchStations(params);
        raw = result.data
            .map((s) => FuelStationResult(s) as SearchResultItem)
            .toList();
      } catch (e, st) { // ignore: unused_catch_stack
        // #2621 — degrade to the other legs rather than aborting the whole
        // route; never silently swallow. #2703 — a single country's feed
        // failing in a multi-country corridor where the overall search still
        // returns results is RECOVERABLE (the chain already retries transient
        // faults), so it must NOT spam a top-level ERROR trace for every
        // failed leg (the 5 UK-feed ERRORs from the field log). Record a
        // diagnostic BREADCRUMB instead — a chronically-failing feed is still
        // visible in any trace that DOES surface, but a recoverable leg outage
        // is silent. (The orchestrator raises one aggregate ERROR only when
        // the final merged corridor result is empty — see
        // `route_search_provider`.)
        BreadcrumbCollector.add(
          'RouteSearch corridor: per-country station query failed',
          detail: 'country=$countryCode fuel=${source.fuel.apiValue} '
              'lat=$lat lng=$lng type=${e.runtimeType}',
        );
        debugPrint('RouteSearch corridor: $countryCode leg failed ($e)');
        continue;
      }
      // Per-country top-N reduce using THIS country's fuel, so the ranking
      // is like-for-like before the slices are concatenated.
      merged.addAll(topNForCountry(
        raw,
        lat: lat,
        lng: lng,
        fuelType: source.fuel,
        topN: topNPerSamplePoint,
        criterion: criterion,
      ));
    }
    return merged;
  };
}

/// Resolve the fuel to price a [station] by, from its origin country.
///
/// Offline country attribution → profile fuel for that country (from
/// [profileFuels]), falling back to [fallback] (the incoming search fuel)
/// when the country has no profile or cannot be resolved.
///
/// Country attribution uses [Countries.countryForStation], which checks the
/// station id PREFIX first (`es-…` → ES) and only then the bounding box.
/// The id prefix is essential here: FR's continental bbox geographically
/// CONTAINS all of Catalonia (#2621), so a bbox-only lookup resolves a
/// Barcelona MITECO station to FR and prices it on FR's E85 (null for ES) —
/// the very '--' bug this fixes. The `es-` prefix every MITECO row carries
/// (#753) overrides that shadow and yields ES → E10.
///
/// #2641 — a 95-octane-unleaded SIBLING fallback after the country grade:
/// the user's Spain profile is Super-E10, but Spain does NOT sell E10 — it
/// sells "Gasolina 95 E5" (769/798 province-08 stations have E5, ~1 has E10).
/// So the ES leg priced by E10 yields `priceFor(E10) == null` → the station is
/// dropped from Best Stops, never cheapest, and shown as '--'. When the
/// resolved grade has no price on this station AND it is a 95-octane unleaded
/// grade (E5 / E10 ONLY — never E85 / E98 / diesel), fall through to the
/// equivalent sibling the station DOES carry. The requested grade is always
/// tried FIRST, so a station that has the requested grade keeps it (the fake
/// ES station carrying E10 stays on E10); only an E5-only real Spanish station
/// resolves to E5. This lives only in the corridor/route resolver — the
/// nearby/single-country strict `station.priceFor` path stays strict (#2510).
/// #2680 — the upper-cased ISO codes of the countries that ACTUALLY produced
/// a *displayable* fuel station in [stations] — a SUBSET of the corridor's
/// queried codes (`RouteSearchResult.corridorCountryCodes`).
///
/// The corridor query (#2622) credits every country it *geographically*
/// crossed. But a cross-border search for a fuel a country doesn't sell
/// (E85 in Spain — #2641: every Spanish MITECO row carries an EMPTY
/// `Precio Bioetanol`) brings back stations with NO price for the displayed
/// grade, shown as "--". Crediting that country's data source in the
/// attribution banner is misleading — it produced nothing the user can act
/// on. This narrows the set to the countries that produced ≥1 station with a
/// resolvable, non-null price.
///
/// "Displayable" mirrors the list/map exactly: a station's grade comes from
/// [fuelForStation] (its OWN country's [profileFuels] grade, with the #2641
/// E5↔E10 95-octane sibling fallback), and the station counts only when
/// `priceFor(thatGrade) != null`. So a Spanish E5-only station priced for an
/// E10 driver still counts (sibling fallback → E5 price), but the same
/// station for an E85 driver does NOT (no E85, no E85 sibling) — exactly the
/// field case where ES must drop off the banner.
///
/// Country attribution uses the SAME [Countries.countryForStation] resolver as
/// [fuelForStation] (id prefix first, then bounding box — #753/#2631), so a
/// Catalonian MITECO station sitting inside FR's continental bbox is still
/// attributed to ES. Only [FuelStationResult]s are considered: EV attribution
/// is not a per-country open-data policy and the banner never credits it. A
/// station whose country cannot be resolved is dropped (no policy to credit).
///
/// Derived from the full found set (`RouteSearchResult.stations`, NOT the
/// Best-Stops display subset) so the banner is stable across the All / Best
/// toggle.
Set<String> contributingCountryCodesFor(
  Iterable<SearchResultItem> stations,
  Map<String, FuelType> profileFuels,
  FuelType fallback,
) {
  final out = <String>{};
  for (final item in stations.whereType<FuelStationResult>()) {
    final code = Countries.countryForStation(
      id: item.station.id,
      lat: item.station.lat,
      lng: item.station.lng,
    )?.code.toUpperCase();
    if (code == null || out.contains(code)) continue;
    // Displayable only — the same grade the list/map prices this station by.
    final grade = fuelForStation(item.station, profileFuels, fallback);
    if (item.station.priceFor(grade) != null) out.add(code);
  }
  return out;
}

FuelType fuelForStation(
  Station station,
  Map<String, FuelType> profileFuels,
  FuelType fallback,
) {
  final code = Countries.countryForStation(
    id: station.id,
    lat: station.lat,
    lng: station.lng,
  )?.code.toUpperCase();
  final grade = code == null ? fallback : (profileFuels[code] ?? fallback);
  if (station.priceFor(grade) != null) return grade; // requested grade first.
  // #2641 — the E5↔E10 95-octane-unleaded sibling fallback (and ONLY that).
  if (grade == FuelType.e10 && station.priceFor(FuelType.e5) != null) {
    return FuelType.e5;
  }
  if (grade == FuelType.e5 && station.priceFor(FuelType.e10) != null) {
    return FuelType.e10;
  }
  return grade;
}

/// Rank one corridor country's slice of a sample point's response to the
/// top [topN] by [criterion], using THAT country's [fuelType].
///
/// Mirrors `BatchQueryHelper`'s per-point reduce (cheapest by price /
/// nearest by distance, unpriced stations sink to the end but are kept) but
/// is invoked per corridor country with the country's own fuel, so the
/// downstream single-fuel reduce in `BatchQueryHelper.queryAll` is a
/// harmless identity. A standalone helper rather than the
/// `@visibleForTesting` `BatchQueryHelper.topNForPoint`.
List<SearchResultItem> topNForCountry(
  List<SearchResultItem> raw, {
  required double lat,
  required double lng,
  required FuelType fuelType,
  required int topN,
  required RouteSearchCriterion criterion,
}) {
  if (raw.length <= topN) return raw;
  final fuel = raw.whereType<FuelStationResult>().toList();
  final other = raw.where((r) => r is! FuelStationResult).toList(growable: false);
  switch (criterion) {
    case RouteSearchCriterion.cheapest:
      fuel.sort((a, b) {
        final pa = a.station.priceFor(fuelType);
        final pb = b.station.priceFor(fuelType);
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pa.compareTo(pb);
      });
    case RouteSearchCriterion.nearest:
      fuel.sort((a, b) {
        final da = distanceKm(a.station.lat, a.station.lng, lat, lng);
        final db = distanceKm(b.station.lat, b.station.lng, lat, lng);
        return da.compareTo(db);
      });
  }
  return [...fuel.take(topN), ...other];
}

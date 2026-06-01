// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_bounding_box.dart';
import '../../../core/logging/error_logger.dart';
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
/// corridor crosses that has a usable station service.
///
/// The country set is [corridorCountries] (every box a route vertex falls
/// inside, order-independent — #2621) UNIONED with the user's PROFILE
/// countries whose bounding box INTERSECTS the route's lat/lng extent
/// (#2621 belt-and-braces, see [countriesTouchingRouteExtent]). The union
/// guarantees a profile-backed country touching the corridor is never
/// silently dropped even if a future detection gap re-shadows it — while
/// the route-extent gate keeps a pure-FR route from pulling in a distant
/// profile country (e.g. PT).
///
/// The set is intersected with the registered, key-satisfied services. A
/// country is SKIPPED when it has no registry entry, or when it requires an
/// API key that isn't configured (the DE / CL / KR demo guard) — we never
/// inject demo stations onto a real route. Per-country fuel is the matching
/// profile's `preferredFuelType` from [profileFuels], falling back to E10
/// for a crossed country the user has no profile for.
Map<String, CountrySource> buildCorridorServiceMap(
  Ref ref,
  RouteInfo route,
  Map<String, FuelType> profileFuels,
) {
  final hasKey = ref.read(storageRepositoryProvider).hasApiKey();
  final codes = corridorCountries(route)
    ..addAll(countriesTouchingRouteExtent(route, profileFuels.keys));
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

/// The subset of [profileCountries] whose registered bounding box
/// INTERSECTS the [route]'s own lat/lng bounding box (#2621).
///
/// Belt-and-braces for the corridor-detection union: even if per-vertex
/// detection were to miss a country (e.g. a future shadowing regression),
/// a profile-backed country whose box overlaps the route's extent is still
/// queried. Gated on ACTUAL extent intersection — NOT mere profile
/// existence — so a pure-FR route does not pull in a distant PT/ES profile
/// the user happens to have configured. Returns upper-cased codes.
Set<String> countriesTouchingRouteExtent(
  RouteInfo route,
  Iterable<String> profileCountries,
) {
  if (route.geometry.isEmpty) return const {};
  var minLat = double.infinity, maxLat = double.negativeInfinity;
  var minLng = double.infinity, maxLng = double.negativeInfinity;
  for (final p in route.geometry) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  final out = <String>{};
  for (final raw in profileCountries) {
    final code = raw.toUpperCase();
    final box = CountryServiceRegistry.boundingBoxFor(code);
    if (box == null) continue;
    // Axis-aligned bbox intersection (overlap on BOTH lat and lng).
    final overlaps = box.minLat <= maxLat &&
        box.maxLat >= minLat &&
        box.minLng <= maxLng &&
        box.maxLng >= minLng;
    if (overlaps) out.add(code);
  }
  return out;
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
/// still resolve, and an empty/failed ES leg is routed to [errorLogger]
/// (ErrorLayer.services) so it is diagnosable rather than silently dropped.
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
      } catch (e, st) {
        // #2621 — degrade to the other legs rather than aborting the whole
        // route; never silently swallow (an empty ES leg must be traceable).
        unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
          'where': 'RouteSearch corridor: per-country station query',
          'country': countryCode,
          'fuel': source.fuel.apiValue,
          'lat': lat,
          'lng': lng,
        }));
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

/// Resolve the fuel to price a station by, from its coordinates.
///
/// Offline bbox → profile fuel for that country (from [profileFuels]),
/// falling back to [fallback] (the incoming search fuel) when the station
/// sits outside every box or in a country with no profile.
FuelType fuelForStation(
  double lat,
  double lng,
  Map<String, FuelType> profileFuels,
  FuelType fallback,
) {
  final code = countryCodeFromLatLng(lat, lng)?.toUpperCase();
  if (code == null) return fallback;
  return profileFuels[code] ?? fallback;
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

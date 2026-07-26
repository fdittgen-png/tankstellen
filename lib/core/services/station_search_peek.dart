// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/search_params.dart';
import '../domain/station.dart';
import '../cache/cache_manager.dart';
import 'country_service_registry.dart';
import 'mixins/station_service_helpers.dart';
import 'service_result.dart';
import 'station_service_chain_codec.dart';

/// #3618 — stale-while-revalidate PEEK for the search surface.
///
/// The chain's `getWithFallback` BLOCKS on the network whenever the
/// fresh tier misses; stale only answers after a network FAILURE. On a
/// warm start with an expired cache the user watched the shimmer for
/// the whole round-trip even though yesterday's stations sat on disk
/// (the DesKilo floor-plan port paints instantly from disk — this is
/// that insight, round-tripped back).
///
/// This helper answers a search from the cache tier — ANY age, no
/// network, synchronous — mirroring [StationServiceChain.searchStations]
/// exactly: same [CacheKey.stationSearch] construction, same
/// [deserializeStationList] codec, same #2926 hard fuel filter. The
/// key-construction twin-ship is pinned by
/// `test/core/services/station_search_peek_test.dart`, which seeds the
/// cache THROUGH a real chain search and requires the peek to find it.
///
/// Bulk-file countries return null: their searches local-filter the
/// persisted national dataset (#2264) and never write per-key search
/// entries. Live surfaces (radar) deliberately do not call this — they
/// keep the blocking mode.
ServiceResult<List<Station>>? peekCachedStationSearch({
  required CacheStrategy cache,
  required String countryCode,
  required SearchParams params,
}) {
  if (CountryServiceRegistry.policyFor(countryCode)?.isBulkFile ?? false) {
    return null;
  }
  final entry = cache.get(CacheKey.stationSearch(
    params.lat,
    params.lng,
    params.radiusKm,
    params.fuelType.apiValue,
    countryCode: countryCode,
    postalCode: params.postalCode,
    locationName: params.locationName,
  ));
  if (entry == null) return null;
  final stations = deserializeStationList(entry.payload);
  if (stations == null || stations.isEmpty) return null;
  final filtered = params.applyFuelFilter
      ? StationServiceHelpers.filterByFuel(stations, params.fuelType)
      : stations;
  if (filtered.isEmpty) return null;
  return ServiceResult(
    data: filtered,
    source: ServiceSource.cache,
    fetchedAt: entry.storedAt,
    // Honest staleness: a still-fresh entry peeked before the network
    // answer is not stale — the banner then shows nothing to retract.
    isStale: entry.isExpired,
  );
}

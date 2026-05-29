// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_provider.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/services/radar/corridor_location_cache.dart';
import '../../../core/services/radar/jit_price_cache.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';

part 'fuel_station_radar_provider.g.dart';

/// Fuel Station Radar data layer (#2283) — the two-tier source that backs the
/// approach detector while a trip is recording.
///
/// It composes:
///
///  - a [CorridorLocationCache] (tier-1) that fetches the station LIST +
///    geolocations for a wide corridor ONCE and caches them long-TTL, so the
///    geofence runs with zero network while driving;
///  - a [JitPriceCache] (tier-3) that fetches the volatile price for just the
///    imminent station(s) on approach, deduped within a short TTL.
///
/// The geofence itself (tier-2) is the existing [ApproachDetector] state
/// machine — this radar only swaps its data source from "search the chain on
/// every poll" to "filter the cached corridor locally + JIT-price the
/// imminent ones". The detector's public API is unchanged.
///
/// ## Bulk vs polled (#2267)
///
/// The corridor fetch closure branches on the active country's
/// [FuelServicePolicy.model]:
///
///  - **bulkFile** (ES/IT/AR/DK): one `searchStations` over the corridor
///    radius local-filters the persisted national dataset the chain already
///    holds (#2267 `PersistentDataset` read-through) — zero network. Prices
///    are already in the bulk slice, so the JIT step is a cache no-op.
///  - **polledApi** (DE/AT/FR/UK/…): one corridor `searchStations` seeds the
///    cache; the cache prefetches the tile ahead at the corridor edge so the
///    geofence stays fed. The JIT price step refreshes the imminent station's
///    price via the per-service rate-limited chain.
class FuelStationRadar {
  final CorridorLocationCache corridorCache;
  final JitPriceCache priceCache;

  /// `true` when the active source is a bulk-file country — the prices are
  /// already in the corridor slice, so the geofence does not need a JIT price
  /// refresh on approach.
  final bool isBulkSource;

  FuelStationRadar({
    required this.corridorCache,
    required this.priceCache,
    required this.isBulkSource,
  });

  /// The data-source closure handed to [ApproachDetector]. Called per poll
  /// with the live GPS + the detector's approach radius. Returns the cached
  /// corridor set with the **imminent** stations (those inside the approach
  /// radius) JIT-priced; the detector then picks its target locally.
  ///
  /// Network cost per call: zero when the corridor tile is already cached and
  /// no imminent station needs a fresh price; otherwise one corridor fetch
  /// (first entry into an area) and/or one JIT price fetch per newly-imminent
  /// station.
  Future<List<Station>> fetchStations(
    double lat,
    double lng,
    double radiusKm,
    String fuelTypeApiValue, {
    double? headingDegrees,
  }) async {
    final corridor = await corridorCache.stationsNear(
      lat,
      lng,
      headingDegrees: headingDegrees,
    );
    if (corridor.isEmpty) return const [];

    final radiusMeters = radiusKm * 1000.0;
    // Identify the imminent stations (inside the approach radius). Only these
    // get a JIT price — the rest stay location-only in the corridor set.
    final result = <Station>[];
    for (final s in corridor) {
      final d = geo.distanceMeters(lat, lng, s.lat, s.lng);
      if (d <= radiusMeters && !isBulkSource) {
        // JIT price (deduped): refresh just this imminent station's price.
        result.add(await priceCache.priceFor(s));
      } else {
        result.add(s);
      }
    }
    return result;
  }
}

/// Builds the [FuelStationRadar] for the active country, reusing the country's
/// chain-backed [StationService] (which already carries the #2267 persisted
/// dataset + per-service rate limiter) for both the corridor fetch and the JIT
/// price fetch.
@Riverpod(keepAlive: true)
FuelStationRadar fuelStationRadar(Ref ref) {
  final country = ref.watch(activeCountryProvider);
  final svc = ref.read(stationServiceProvider);
  final policy = CountryServiceRegistry.policyFor(country.code);
  final isBulk = policy?.isBulkFile ?? false;

  final corridorCache = CorridorLocationCache(
    isBulk: isBulk,
    fetchCorridor: (lat, lng, radiusKm) async {
      try {
        final result = await svc.searchStations(
          SearchParams(
            lat: lat,
            lng: lng,
            radiusKm: radiusKm,
            // Locations are fuel-agnostic — fetch the widest set so the
            // geofence sees every nearby forecourt regardless of the
            // driver's fuel type. The JIT step reads the per-fuel price.
            fuelType: FuelType.all,
            sortBy: SortBy.distance,
          ),
        );
        return result.data;
      } on Object {
        return const <Station>[];
      }
    },
  );

  final priceCache = JitPriceCache(
    // The short TTL tracks the polled source's own search TTL when known, so a
    // re-approach within the upstream's price cadence never re-hits the API.
    ttl: policy?.searchResultTtl != null && policy!.searchResultTtl > Duration.zero
        ? policy.searchResultTtl
        : JitPriceCache.defaultTtl,
    fetchPrice: (station) async {
      try {
        // A tight single-station search around the imminent station refreshes
        // its price through the rate-limited chain. We match the returned
        // station by id and prefer it; if the upstream doesn't return it we
        // keep the location-only station.
        final result = await svc.searchStations(
          SearchParams(
            lat: station.lat,
            lng: station.lng,
            radiusKm: 1.0,
            fuelType: FuelType.all,
            sortBy: SortBy.distance,
          ),
        );
        // Match the imminent station by id; if the upstream doesn't return it
        // (id drift across sources), keep the location-only station.
        return result.data.where((s) => s.id == station.id).firstOrNull;
      } on Object {
        return null;
      }
    },
  );

  return FuelStationRadar(
    corridorCache: corridorCache,
    priceCache: priceCache,
    isBulkSource: isBulk,
  );
}

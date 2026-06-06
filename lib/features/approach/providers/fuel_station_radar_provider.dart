// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/background/provider_request_budget.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/country_service_registry.dart';
import '../../../core/services/diagnostics/data_access_event.dart';
import '../../../core/services/diagnostics/data_access_recorder_provider.dart';
import '../../../core/services/radar/corridor_location_cache.dart';
import '../../../core/services/radar/jit_price_cache.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/utils/station_extensions.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';

part 'fuel_station_radar_provider.g.dart';

/// Tight near-radius (km) the polled corridor fetch ALSO queries and merges
/// into the wide corridor (#2813). The wide corridor is row-capped with no
/// distance ordering (e.g. FR `within_distance(60km)` + `limit:50`), so in a
/// sparse/suburban area — exactly where few near stations are easily truncated
/// by far-area density — the genuinely-nearest forecourts drop out and the
/// "Closest station" card shows a far one. A sparse near-radius fetch isn't
/// hit by the cap, so it reliably carries the nearest stations back. 15 km
/// comfortably covers the default 10 km search radius.
const double kCorridorNearMergeRadiusKm = 15.0;

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

    // #2926 — the corridor LOCATIONS are fetched fuel-agnostically (the
    // geofence must see every nearby forecourt), but the result handed back to
    // the caller must honour the selected fuel so the radar's superset is
    // consistent with the in-radius search. Resolve the requested fuel here;
    // `FuelType.all` (and any unknown apiValue) keeps every station.
    final fuel = FuelType.fromString(fuelTypeApiValue);

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

    // Fuel-filter the corridor result. A station is dropped only when we
    // POSITIVELY know it does not sell the fuel — i.e. it carries price data
    // but none (`> 0`) for the selected fuel. Location-only corridor stations
    // (not yet JIT-priced for a polled source) carry no price for ANY fuel and
    // are KEPT, so the trip geofence net stays intact and they're re-evaluated
    // once they become imminent and get priced. `FuelType.all` keeps all.
    return _fuelConsistent(result, fuel);
  }

  /// Drop stations that positively lack [fuel] (have priced fuels, but not this
  /// one). Keep `FuelType.all`, non-priced fuels (EV / hydrogen), and
  /// location-only stations with no price data at all (#2926).
  List<Station> _fuelConsistent(List<Station> stations, FuelType fuel) {
    if (fuel == FuelType.all) return stations;
    return stations
        .where((s) {
          final price = s.priceFor(fuel);
          if (price != null && price > 0) return true;
          // Keep location-only stations (no price for ANY fuel) so a polled
          // source's far corridor net survives until JIT-pricing; drop a
          // station that IS priced for other fuels but not this one.
          return !_hasAnyPrice(s);
        })
        .toList(growable: false);
  }

  /// Whether [s] carries a usable (`> 0`) price for at least one fuel — i.e. it
  /// has been priced (bulk slice or JIT), as opposed to a location-only
  /// corridor row whose prices are all null.
  bool _hasAnyPrice(Station s) =>
      _positive(s.e5) ||
      _positive(s.e10) ||
      _positive(s.e98) ||
      _positive(s.diesel) ||
      _positive(s.dieselPremium) ||
      _positive(s.e85) ||
      _positive(s.lpg) ||
      _positive(s.cng);

  static bool _positive(double? v) => v != null && v > 0;
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

  // #2932 — the shared foreground+background per-provider request budget and
  // the dev-only data-access tracer, so a corruption-forced corridor refetch
  // (the proximity validator inside the cache) still honours the provider's
  // minInterval and is distinguishable from a plain TTL refetch in the trace.
  final budget = ProviderRequestBudget(ref.read(storageRepositoryProvider));
  final recorder = ref.read(dataAccessRecorderProvider);
  final minInterval = policy?.minInterval;
  final errorSource =
      CountryServiceRegistry.entryFor(country.code)?.errorSource;

  final corridorCache = CorridorLocationCache(
    isBulk: isBulk,
    // Rate-gate the staleness/corruption-forced refetch ONLY (a first-entry or
    // TTL refetch is never gated) on the shared budget, so a poisoned/far
    // cache is replaced without breaching the provider's published cadence.
    canRefetch: () => budget.canFire(country.code, minInterval),
    onRefetch: () {
      // Stamp the shared budget (so a background scan sees this hit) and emit a
      // staleness-tagged DataAccessEvent (#2824) the moment a corruption-forced
      // refetch fires — `isStale: true` is what tells a forced refetch apart
      // from a normal TTL-expiry one in the exported trace.
      budget.recordRequest(country.code);
      recorder?.add(DataAccessEvent(
        at: DateTime.now(),
        monotonicMicros: recorder.monotonicMicros,
        country: country.code,
        source: (errorSource ?? ServiceSource.cache).name,
        endpoint: DataAccessEndpoint.corridorPrefetch,
        hit: DataAccessHit.networkApi,
        isStale: true,
      ));
    },
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
        // #2813 — a polled source returns the wide corridor under a hard row
        // cap with no distance ordering (e.g. FR `within_distance(60km)` +
        // `limit:50`), so in a dense area the genuinely-NEAREST forecourts can
        // be truncated out — leaving the recording "Closest station" card and
        // the approach detector showing a far station the in-radius search
        // would never pick. Merge a tight near-radius fetch (sparse → not row-
        // capped) by id so the cached corridor always contains the nearest
        // stations. Bulk-file sources read the full local dataset (no cap), so
        // the wide fetch is already complete and the merge is skipped.
        if (isBulk || radiusKm <= kCorridorNearMergeRadiusKm) {
          return result.data;
        }
        final byId = {for (final s in result.data) s.id: s};
        try {
          final near = await svc.searchStations(
            SearchParams(
              lat: lat,
              lng: lng,
              radiusKm: kCorridorNearMergeRadiusKm,
              fuelType: FuelType.all,
              sortBy: SortBy.distance,
            ),
          );
          for (final s in near.data) {
            byId[s.id] = s;
          }
        } on Object {
          // Wide-corridor-only on a near-fetch failure (offline / rate limit).
        }
        return byId.values.toList(growable: false);
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

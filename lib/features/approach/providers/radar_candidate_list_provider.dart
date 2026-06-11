// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/utils/station_extensions.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/domain/search_params.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import 'effective_approach_state_provider.dart';
import 'fuel_station_radar_provider.dart';

part 'radar_candidate_list_provider.g.dart';

/// Ranked list of nearby **priced** fuel stations for the swipe-to-page
/// radar card (#2633).
///
/// The single-station [nearestStationRadarProvider] only surfaces the
/// nearest priced station; the swipe gesture needs the FULL distance-
/// ranked candidate set so the card can advance to the next-nearest on a
/// swipe-left and restore the previous one on a swipe-right.
///
/// Like [nearestStationRadarProvider] this fires ONLY on the polling
/// fallback path: while the driver is still approaching the detector
/// emits [ApproachPolling] carrying the live GPS fix it polls against.
/// We reuse **that same** position — no new geolocator subscription.
///
/// Returns:
/// - `const []` for any non-[ApproachPolling] state — the in-radius /
///   leaving states render a single locked target straight off the
///   approach state, so the swipe page-set stays out of the way; idle /
///   null has no GPS fix yet.
/// - the distance-sorted [Station] list filtered to those carrying a
///   price for the effective fuel (`priceFor(fuel)` non-null and `> 0`)
///   — the same priced filter as `approach_detector.dart` and
///   [nearestStationRadarProvider], so the card never pages onto a `--`
///   placeholder price the driver can't compare (#2583).
/// - `const []` on a radar / chain failure (the provider re-runs on the
///   next approach-state tick).
///
/// ### Data source (#2664)
///
/// The page-set routes through the cache-first [fuelStationRadarProvider]
/// — the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km set
/// on every poll. The ranked page-set therefore matches exactly what the
/// in-radius layout would surface.
///
/// ### In-radius superset merge (#2965)
///
/// The cached corridor is built from a polled-source `searchStations` that is
/// row-capped with **no distance ordering** (e.g. FR `within_distance(60km)` +
/// `limit:50`). In a dense area the un-ordered slice can truncate out the
/// genuinely-nearest forecourt — leaving this card showing **"no station
/// nearby"** while a priced station sits a few hundred metres away. To guarantee
/// the candidate set is a SUPERSET of the in-radius search (exactly the #2806
/// rescue the on-search radar already applies), we also issue a DIRECT in-radius
/// `searchStations` at `profile.approachRadiusKm` and merge it into the corridor
/// set (dedup by id, the in-radius row winning — it carries the freshest
/// per-fuel price/distance). A failed in-radius fetch degrades to corridor-only,
/// never breaking the card. The deeper cure (a distance `order_by` on the FR
/// corridor query) is tracked separately (#2966).
@riverpod
Future<List<Station>> radarCandidateList(Ref ref) async {
  final approach = ref.watch(effectiveApproachStateProvider);

  // In-radius / leaving carry a single locked target the card renders
  // directly — the swipe page-set is the polling-fallback affordance only.
  if (approach is! ApproachPolling) return const [];

  final gps = approach.gps;
  final fuel = ref.watch(effectiveFuelTypeProvider);
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return const [];
  final radar = ref.read(fuelStationRadarProvider);

  try {
    // Cache-first corridor (tier-1) + JIT price for the imminent station(s)
    // (tier-3), at the user's default radar radius — the same envelope the
    // in-radius detector polls with. Zero network on a warm tile / a
    // bulk-file country.
    final corridor = await radar.fetchStations(
      gps.latitude,
      gps.longitude,
      profile.approachRadiusKm,
      fuel.apiValue,
    );

    // #2965 — merge a DIRECT in-radius search so the candidate set is always a
    // SUPERSET of the in-radius search (mirrors the on-search radar's #2806
    // rescue). The corridor's polled source is row-capped with no distance
    // ordering, so in a dense area the genuinely-nearest forecourt can be
    // truncated out and this card would show "no station nearby" while a priced
    // station is metres away. Best-effort: corridor-only on failure.
    final inRadius = await _inRadiusStations(
      ref,
      gps.latitude,
      gps.longitude,
      profile.approachRadiusKm,
      fuel,
    );

    // Dedup by id, the in-radius row winning — it carries the freshest per-fuel
    // price/distance. Then keep only stations the driver can actually price-
    // compare (a non-null, positive [priceFor] for the effective fuel) so a
    // swipe never lands on a `--` price row (#2583), and distance-sort from the
    // live fix (the corridor is cached in fetch order, not distance order).
    final byId = <String, Station>{
      for (final s in corridor) s.id: s,
      for (final s in inRadius) s.id: s,
    };
    final priced = byId.values
        .where((s) {
          final price = s.priceFor(fuel);
          return price != null && price > 0;
        })
        .toList(growable: false)
      ..sort((a, b) => geo
          .distanceMeters(gps.latitude, gps.longitude, a.lat, a.lng)
          .compareTo(
            geo.distanceMeters(gps.latitude, gps.longitude, b.lat, b.lng),
          ));
    // #2808 — re-stamp each row's LIVE distance (km) from the current fix.
    // The corridor stations carry a `dist` frozen at the corridor-fetch
    // centre, so without this the swipe-card proximity bar + caption never
    // move as the driver approaches. Mirrors the on-search radar.
    return [
      for (final s in priced)
        s.copyWith(
          dist: geo.distanceMeters(
                gps.latitude,
                gps.longitude,
                s.lat,
                s.lng,
              ) /
              1000.0,
        ),
    ];
  } on Object {
    // Radar / chain failure — treat as "no stations nearby". The provider
    // re-runs on the next approach-state tick.
    return const [];
  }
}

/// A direct in-radius station fetch around the live fix (#2965), mirroring the
/// regular search + the on-search radar's `_inRadiusStations`, so the candidate
/// list is a superset of the in-radius search and a dense-corridor row cap can
/// never truncate out the genuinely-nearest forecourt.
///
/// **Never throws.** Returns `const []` on any failure (offline, rate-limit, a
/// service that doesn't support geo search) so the candidate list degrades to
/// its cached corridor rather than collapsing the card.
Future<List<Station>> _inRadiusStations(
  Ref ref,
  double lat,
  double lng,
  double radiusKm,
  FuelType fuel,
) async {
  try {
    final result = await ref.read(stationServiceProvider).searchStations(
          SearchParams(
            lat: lat,
            lng: lng,
            radiusKm: radiusKm,
            fuelType: fuel,
            sortBy: SortBy.distance,
          ),
        );
    return result.data;
  } on Object {
    return const <Station>[];
  }
}

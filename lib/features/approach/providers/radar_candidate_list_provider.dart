// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/station.dart';
import '../../../core/services/approach_detector.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/services/radar/radar_ranking.dart';
import 'effective_approach_state_provider.dart';
import 'fuel_station_radar_provider.dart';
import '../../../core/services/radar/radar_in_radius_cache_provider.dart';

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
    // bulk-file country. #3256 — thread the live heading so the cache
    // prefetches the tile ahead before the driver crosses into it.
    final corridor = await radar.fetchStations(
      gps.latitude,
      gps.longitude,
      profile.approachRadiusKm,
      fuel.apiValue,
      headingDegrees: geo.sanitizedHeading(gps.heading),
    );

    // #2965 — merge a DIRECT in-radius search so the candidate set is always a
    // SUPERSET of the in-radius search (mirrors the on-search radar's #2806
    // rescue): the corridor's polled source is row-capped with no distance
    // ordering, so a dense area can truncate out the genuinely-nearest
    // forecourt. #3254 — this merge is now movement+time-gated, so it issues
    // at most one chain search per the provider's minInterval (not one per
    // poll), and reuses its cached merge in between — bounding the rate-limit
    // queue a moving car used to flood.
    final inRadius = await ref.read(radarInRadiusCacheProvider).stationsNear(
          gps.latitude,
          gps.longitude,
          profile.approachRadiusKm,
        );

    // #3267 — the single distance-ranking authority: dedup (the in-radius row
    // wins — freshest per-fuel price/distance), keep only stations priced for
    // the effective fuel so a swipe never lands on a `--` row (#2583), live-
    // stamp each row's distance off the current fix (#2808 — the corridor
    // `dist` is frozen at fetch time) and distance-sort nearest-first.
    return RadarRanking.rank(
      [...corridor, ...inRadius],
      lat: gps.latitude,
      lng: gps.longitude,
      fuel: fuel,
      requirePrice: true,
    );
  } on Object {
    // Radar / chain failure — treat as "no stations nearby". The provider
    // re-runs on the next approach-state tick.
    return const [];
  }
}

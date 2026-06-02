// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/utils/station_extensions.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../search/domain/entities/station.dart';
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
    final stations = await radar.fetchStations(
      gps.latitude,
      gps.longitude,
      profile.approachRadiusKm,
      fuel.apiValue,
    );
    // The corridor set is cached in fetch order, not distance order — sort
    // by distance from the live fix, then keep only stations the driver can
    // actually price-compare (a non-null, positive [priceFor] for the
    // effective fuel) so a swipe never lands on a `--` price row (#2583).
    return (stations
        .where((s) {
          final price = s.priceFor(fuel);
          return price != null && price > 0;
        })
        .toList(growable: false)
      ..sort((a, b) => geo
          .distanceMeters(gps.latitude, gps.longitude, a.lat, a.lng)
          .compareTo(
            geo.distanceMeters(gps.latitude, gps.longitude, b.lat, b.lng),
          )));
  } on Object {
    // Radar / chain failure — treat as "no stations nearby". The provider
    // re-runs on the next approach-state tick.
    return const [];
  }
}

// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/station_extensions.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import 'effective_approach_state_provider.dart';

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
/// We reuse **that same** position — no new geolocator subscription —
/// and query the search chain for the surrounding stations.
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
/// - `const []` on a network / chain failure (the provider re-runs on
///   the next approach-state tick).
@riverpod
Future<List<Station>> radarCandidateList(Ref ref) async {
  final approach = ref.watch(effectiveApproachStateProvider);

  // In-radius / leaving carry a single locked target the card renders
  // directly — the swipe page-set is the polling-fallback affordance only.
  if (approach is! ApproachPolling) return const [];

  final gps = approach.gps;
  final fuel = ref.watch(effectiveFuelTypeProvider);
  final svc = ref.read(stationServiceProvider);

  // Radius mirrors the approach detector's search window (10 km), so the
  // ranked page-set matches what the in-radius layout would surface.
  try {
    final result = await svc.searchStations(
      SearchParams(
        lat: gps.latitude,
        lng: gps.longitude,
        radiusKm: 10.0,
        fuelType: fuel,
        sortBy: SortBy.distance,
      ),
    );
    // Already distance-sorted; keep only stations the driver can actually
    // price-compare (a non-null, positive [priceFor] for the effective
    // fuel) so a swipe never lands on a `--` price row (#2583).
    return result.data
        .where((s) {
          final price = s.priceFor(fuel);
          return price != null && price > 0;
        })
        .toList(growable: false);
  } on Object {
    // Network / chain failure — treat as "no stations nearby". The
    // provider re-runs on the next approach-state tick.
    return const [];
  }
}

// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import '../../../core/services/service_providers.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import 'effective_approach_state_provider.dart';

part 'nearest_station_radar_provider.g.dart';

/// Fallback "radar" lookup for the trip-screen [TripRadarCard] (#2380).
///
/// The approach detector only flips into [ApproachInRadius] once the
/// driver is inside the configured geo-fence. Outside the radius it
/// emits [ApproachPolling], which already carries the live GPS fix the
/// detector is polling against. This provider reuses **that same**
/// position — no new GPS subscription — to surface the single nearest
/// fuel station + its price so the card has something useful to show
/// while the driver is still approaching.
///
/// Returns:
/// - `null` when the effective approach state is [ApproachInRadius] or
///   [ApproachLeaving] — the card renders those directly off the
///   approach state, so the fallback stays out of the way.
/// - `null` when the state is [ApproachIdle] / null (no GPS fix yet) —
///   the card shows its "scanning" placeholder.
/// - the nearest [Station] (sorted by distance) for an
///   [ApproachPolling] fix, or `null` when the search chain returns
///   nothing in range.
///
/// The lookup mirrors the detector's own `fetchStations` callback
/// ([approachStateProvider]) — same `searchStations` chain, same
/// effective fuel type — so the price column the card reads matches
/// what the in-radius layout would show.
@riverpod
Future<Station?> nearestStationRadar(Ref ref) async {
  final approach = ref.watch(effectiveApproachStateProvider);

  // The in-radius / leaving states already carry a target station the
  // card renders directly; don't run a redundant search for them.
  if (approach is! ApproachPolling) return null;

  final gps = approach.gps;
  final fuel = ref.watch(effectiveFuelTypeProvider);
  final svc = ref.read(stationServiceProvider);

  // Radius mirrors the approach detector's search window (its callback
  // queries `radiusMeters / 1000` km); 10 km keeps the fallback useful
  // before the driver crosses the (smaller) geo-fence.
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
    return result.data.isEmpty ? null : result.data.first;
  } on Object {
    // Network / chain failure — treat as "no station nearby". The
    // provider re-runs on the next approach-state tick.
    return null;
  }
}

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
/// - the nearest [Station] **that has a price for the effective fuel**
///   (the distance-sorted list filtered to `priceFor(fuel) > 0`) for an
///   [ApproachPolling] fix, or `null` when nothing in range is priced
///   for the driver's fuel (#2583). Unpriced nearest stations are
///   skipped so the card only ever surfaces a station the driver can
///   actually price-compare — never a `--` placeholder price.
///
/// ### Data source (#2664)
///
/// The lookup routes through the cache-first [fuelStationRadarProvider] —
/// the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km
/// set on every poll. The price column the card reads therefore matches
/// exactly what the in-radius layout would show.
@riverpod
Future<Station?> nearestStationRadar(Ref ref) async {
  final approach = ref.watch(effectiveApproachStateProvider);

  // The in-radius / leaving states already carry a target station the
  // card renders directly; don't run a redundant search for them.
  if (approach is! ApproachPolling) return null;

  final gps = approach.gps;
  final fuel = ref.watch(effectiveFuelTypeProvider);
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return null;
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
      // #3256 — thread the live heading so the corridor cache prefetches the
      // tile ahead; a standstill/first-fix sentinel maps to null (no prefetch).
      headingDegrees: geo.sanitizedHeading(gps.heading),
    );
    // #3267 — the single distance-ranking authority: dedup, drop forecourts
    // unpriced for the effective fuel (#2583), re-stamp the LIVE distance off
    // the current fix (#2808 — the corridor `dist` is frozen at fetch time so
    // without this the PiP bar + caption never move) and return the nearest.
    // `null` when nothing in range is priced.
    return RadarRanking.nearestPriced(
      stations,
      lat: gps.latitude,
      lng: gps.longitude,
      fuel: fuel,
    );
  } on Object {
    // Radar / chain failure — treat as "no station nearby". The provider
    // re-runs on the next approach-state tick.
    return null;
  }
}

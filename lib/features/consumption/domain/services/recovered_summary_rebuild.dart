// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../trip_recorder.dart';
import 'trip_consumption_reliability.dart';

/// Rebuilds a crash-recovered trip's [TripSummary] from its persisted
/// samples (#3597).
///
/// The OBD2 WAL snapshot's summary is deliberately a skeleton — distance,
/// maxRpm and timestamps only — because computing a full summary on every
/// flush would be wasted work on the happy path. The salvage path
/// (`_finalizeRecoveredSnapshot`, #1347) used to save that skeleton
/// verbatim, so every crash-ended drive lost its consumption figure,
/// idle/high-RPM time and cold-start flag. With the process dying daily
/// under the Play integrity wrapper (#3590), that stopped being cosmetic:
/// a 92 km fully-measured field trip surfaced with `avgLPer100Km: null`.
///
/// The rebuild replays the samples through the canonical [TripRecorder]
/// with the SAME 15 s integration-gap cap the live OBD2 controller uses,
/// so a mid-trip dropout hole can neither fabricate distance nor ride a
/// stale fuel rate. Two skeleton fields are kept over the replay, per
/// #3251: the live controller's gap-capped `distanceKm` and its
/// `distanceSource` provenance — re-deriving distance from the raw buffer
/// is exactly the #1927 bug. The consumption average is then recomputed
/// against that trusted distance. IMU counts stay absent: the inertial
/// ring died with the process, and pretending otherwise would defeat the
/// #2895 veto semantics.
TripSummary rebuildRecoveredSummary({
  required TripSummary skeleton,
  required List<TripSample> samples,
  double maxIntegrationGapSeconds = 15.0,
}) {
  if (samples.isEmpty) return skeleton;

  final recorder =
      TripRecorder(maxIntegrationGapSeconds: maxIntegrationGapSeconds);
  for (final s in samples) {
    // Thread the trip's distance provenance so harsh scoring keeps the
    // #2653/#2895 source gate (suppressed on derived speed) on replay.
    recorder.onSample(s, distanceSource: skeleton.distanceSource);
  }
  final replay = recorder.buildSummary();

  final distanceKm =
      skeleton.distanceKm > 0 ? skeleton.distanceKm : replay.distanceKm;
  final liters = replay.fuelLitersConsumed;
  // Same ratio gates as the live stop path: a sparse fuel cadence already
  // nulled `liters` inside the replay; a tiny distance suppresses only
  // the blow-up-prone average, never the measured litres (#2835).
  final avgLPer100Km = liters != null && isDistanceReliableForRatio(distanceKm)
      ? liters / distanceKm * 100.0
      : replay.avgLPer100Km;

  return replay.copyWith(
    distanceKm: distanceKm,
    distanceSource: skeleton.distanceSource,
    avgLPer100Km: avgLPer100Km,
    startedAt: skeleton.startedAt ?? replay.startedAt,
    endedAt: skeleton.endedAt ?? replay.endedAt,
  );
}

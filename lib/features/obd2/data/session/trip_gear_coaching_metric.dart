// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/vehicle_profile.dart';
import '../../../trips/api.dart';

/// RPM ceiling used by the gear-inference coaching metric (#1263 phase
/// 2). The "seconds below optimal gear" heuristic counts an interval
/// when the next gear up would still keep the engine at or above this
/// value — i.e. the current selection is unnecessarily low. 2200 RPM
/// matches the issue body's reference point: well above the 1500-1800
/// RPM lugging band on most petrol engines but still within the
/// cruise sweet-spot the coaching line targets. Hardcoded for phase 2;
/// phase 3+ may promote this to a per-vehicle field if the spread
/// between engine families warrants it.
const double kOptimalRpmCeiling = 2200.0;

/// Compute the gear-inference coaching metric (#1263 phase 2).
///
/// #4034 (epic #4032) — a pure function in its own library rather than a
/// method on the recording controller's `part` mixin: it reads the
/// vehicle profile and the trip's captured samples and nothing else, so
/// it never needed the controller's private scope.
///
/// Returns null when:
///  - no vehicle profile is wired (we don't know the tyre size);
///  - the vehicle type is [VehicleType.ev] (no gears to coach);
///  - the captured-samples buffer is empty (no data to cluster);
///  - [inferGears] returns fewer than two centroids (degenerate);
///  - [computeSecondsBelowOptimalGear] reports the heuristic as not
///    computable.
///
/// Returns a non-negative double otherwise — seconds during the trip
/// where a higher gear would have kept RPM above [kOptimalRpmCeiling].
double? computeGearCoachingMetric({
  required VehicleProfile? vehicle,
  required List<TripSample> capturedSamples,
}) {
  if (vehicle == null) return null;
  // EV bypass — pure-electric drivetrains have no manual / discrete
  // gears. Hybrids DO have a step-ratio transmission on the combustion
  // side, so they fall through to the inference path.
  if (vehicle.type == VehicleType.ev) return null;
  if (capturedSamples.isEmpty) return null;
  final tireC = vehicle.tireCircumferenceMeters;
  if (tireC <= 0) return null;
  final result = inferGears(
    samples: capturedSamples,
    tireCircumferenceMeters: tireC,
    priorCentroids: vehicle.gearCentroids,
  );
  if (result.centroids.length < 2) return null;
  return computeSecondsBelowOptimalGear(
    gearAssignments: result.samples
        .map((s) => (timestamp: s.timestamp, gear: s.gear))
        .toList(growable: false),
    optimalRpmCeiling: kOptimalRpmCeiling,
    samples: capturedSamples,
    centroids: result.centroids,
  );
}

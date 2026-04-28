/// Gear-based coaching metrics derived from [inferGears] output
/// (#1263 phase 2).
///
/// Split out of `gear_inference.dart` to keep that file under the
/// 300-LOC budget (Refs #563). Library-private (`part of`) — no public
/// API surface changes; existing imports of `gear_inference.dart`
/// continue to resolve `computeSecondsBelowOptimalGear` without churn.
part of 'gear_inference.dart';

/// Compute total seconds the trip spent below the optimal gear
/// (one gear lower than where RPM would drop below
/// [optimalRpmCeiling]). Pure — does not mutate inputs.
///
/// Heuristic: for each consecutive pair of [gearAssignments] where
/// both have non-null gears AND the current gear is below the top
/// inferred gear, ask "would the next gear up keep the engine at or
/// above [optimalRpmCeiling] at the same speed?" If yes, the current
/// gear is unnecessarily low — count the Δt in seconds. If no, the
/// driver is already at the lowest gear that keeps RPM above the
/// ceiling, so the current selection is acceptable.
///
/// The next-gear RPM is predicted by the centroid ratio:
///
/// ```
///   nextGearRpm = currentRpm × centroids[gearIdx + 1]
///                            / centroids[gearIdx]
/// ```
///
/// Recall (see library docs) that centroids are sorted ascending and
/// `centroidIndex = targetGearCount - gear`, so a higher gear maps to
/// a lower centroid index. Going UP one gear means going DOWN one
/// centroid index, and the centroids[lower] / centroids[higher]
/// ratio is < 1 → predicted RPM drops, as intended.
///
/// Returns 0.0 when [gearAssignments] is empty or all gear values
/// are null. Returns null when fewer than two distinct gears were
/// inferred (can't compare to "next gear up").
double? computeSecondsBelowOptimalGear({
  required List<({DateTime timestamp, int? gear})> gearAssignments,
  required double optimalRpmCeiling,
  required List<TripSample> samples,
  required List<double> centroids,
}) {
  // Need at least two distinct centroids to define a "next gear up";
  // otherwise the heuristic isn't computable.
  if (centroids.length < 2) return null;
  if (gearAssignments.isEmpty) return 0.0;
  if (gearAssignments.length != samples.length) {
    // Defensive — a length mismatch would silently misalign per-pair
    // RPM lookups. Return null rather than miscount.
    return null;
  }

  // Determine the highest inferred gear we'll see — labels follow
  // [inferGears]'s convention: gear = targetGearCount - centroidIndex,
  // so the maximum gear label equals the centroids list length (which
  // [inferGears] guarantees == targetGearCount on success). Computing
  // it from the centroid count keeps this helper robust to callers
  // that pass a shorter list.
  final maxGear = centroids.length;

  var totalSeconds = 0.0;
  for (var i = 0; i < gearAssignments.length - 1; i++) {
    final current = gearAssignments[i];
    final next = gearAssignments[i + 1];
    final gear = current.gear;
    if (gear == null || next.gear == null) continue;
    if (gear >= maxGear) continue; // already top gear, no "next up"

    final dt =
        next.timestamp.difference(current.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    // Map the current gear label back to its centroid index. With
    // gearLabel = targetGearCount - centroidIndex, the centroid index
    // for the current gear is `maxGear - gear`, and the index for the
    // next gear up (one physical gear higher) is `maxGear - (gear + 1)`.
    final currentIdx = maxGear - gear;
    final nextIdx = maxGear - (gear + 1);
    // Defensive bounds — a malformed centroids list could produce
    // out-of-range indices. Skip the pair rather than throw.
    if (currentIdx < 0 || currentIdx >= centroids.length) continue;
    if (nextIdx < 0 || nextIdx >= centroids.length) continue;
    final currentCentroid = centroids[currentIdx];
    if (currentCentroid <= 0) continue;

    final currentRpm = samples[i].rpm;
    final predictedNextGearRpm =
        currentRpm * centroids[nextIdx] / currentCentroid;
    if (predictedNextGearRpm >= optimalRpmCeiling) {
      // The next gear up would still hold RPM above the ceiling, so
      // the current gear was unnecessarily low — count this interval.
      totalSeconds += dt;
    }
  }

  return totalSeconds;
}

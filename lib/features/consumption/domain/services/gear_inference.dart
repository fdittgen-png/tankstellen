/// Pure-logic gear inference for the "labouring in low gear" coaching
/// signal (#1263 phase 1).
///
/// ## Why
///
/// A common fuel-economy mistake — driving 60 km/h in 3rd instead of
/// 5th — is invisible to the driving-insights view today. RPM is
/// logged, speed is logged, but the *ratio* (which is gear-correlated)
/// isn't surfaced. This module derives a per-sample gear label from
/// `engineRpm / wheelRpm` clusters; phase 2 will integrate the labels
/// into [TripSummary] and surface a coaching line.
///
/// ## The math
///
/// Given a tyre circumference C (m), a sample's wheel angular velocity
/// in RPM is:
///
/// ```
///   wheelRpm = (speedKmh / 3.6) / C * 60
/// ```
///
/// The drivetrain ratio (engine RPM / wheel RPM) is:
///
/// ```
///   ratio = rpm / wheelRpm
///         = rpm / (speedKmh / 3.6 / C * 60)
/// ```
///
/// This is **gear ratio × final-drive ratio**, not the textbook gear
/// ratio in isolation — but the final-drive constant is the same
/// across every sample on a given vehicle, so the cluster centroids
/// still separate cleanly into one per gear.
///
/// Higher ratio → more engine revs per wheel rev → lower physical
/// gear (1st has the highest ratio). When we sort centroids
/// ascending, **centroid index 0 maps to the top gear** (e.g. 5th in
/// a 5-speed) and **centroid index `targetGearCount - 1` maps to 1st
/// gear**. The gear LABEL returned per sample uses the conventional
/// human-readable numbering: `gear = 1` is 1st (lowest physical
/// gear), `gear = 5` is 5th (top). So:
///
/// ```
///   gearLabel = targetGearCount - centroidIndex
/// ```
///
/// ## Heuristic thresholds
///
/// - **Idle skip** (`speedKmh < 5` OR `rpm < 500`): below 5 km/h the
///   speed sensor is too noisy to derive a meaningful ratio, and at
///   <500 RPM the engine is either off or stalling. Both paths
///   produce huge division-by-near-zero ratios that would dominate
///   any clustering.
/// - **Outlier trim** (ratio > 99th × 2 or < 1st / 2 of in-trip
///   percentiles): clutch transitions and shift events transiently
///   produce ratios outside the gear band — including them would
///   smear the centroids. We compute percentiles on the SURVIVING
///   (post-idle-skip) ratios and trim from there.
///
/// ## Algorithm
///
/// 1-D k-means with up to 10 iterations, ε = 0.5 % centroid-shift
/// convergence:
///
/// 1. Filter samples by the idle-skip rules → list of valid ratios.
/// 2. Compute the 1st and 99th percentiles, drop outliers.
/// 3. Seed centroids: if `priorCentroids` is supplied, use it; else
///    take the 10th / 30th / 50th / 70th / 90th percentile (for
///    `targetGearCount = 5`, generalised to `((2i + 1) / (2k))` for
///    arbitrary k).
/// 4. Iterate: assign each ratio to its nearest centroid (Euclidean
///    distance in 1-D = |a - b|), recompute centroid as the mean of
///    its assigned ratios. Stop when max relative shift < 0.5 % or
///    after 10 iterations.
/// 5. Sort centroids ascending. Re-assign every sample (including
///    the originally-skipped ones, which receive `gear = null`).
///
/// ## Degenerate cases
///
/// Fewer than `targetGearCount` valid ratios: the algorithm still
/// runs but the resulting centroids are unreliable. Callers should
/// only persist centroids from trips with ≥ ~50 valid samples
/// covering at least 3 distinct ratio bands.
///
/// Idle-only fixtures (every sample fails the idle-skip rule): the
/// function returns an empty centroids list and `gear = null` for
/// every input sample. No exceptions thrown.
library;

import 'package:flutter/foundation.dart';

import '../trip_recorder.dart';

/// One sample's inferred gear label, paired with its source timestamp
/// so the caller can re-align inferred gears with other per-sample
/// metrics (engine load, throttle, etc.) without re-iterating the
/// original `Iterable<TripSample>`.
@immutable
class InferredGearSample {
  /// Source sample timestamp.
  final DateTime timestamp;

  /// Inferred gear label (1 = 1st gear, `targetGearCount` = top
  /// gear). `null` when the sample was skipped — idle, sub-threshold,
  /// or an outlier ratio. The caller must treat `null` as "no
  /// signal" rather than "neutral".
  final int? gear;

  const InferredGearSample({required this.timestamp, required this.gear});
}

/// Output of [inferGears] — per-sample gear assignments plus the
/// cluster centroids that produced them. The centroids are the
/// caching unit: persist them on the per-vehicle profile so the next
/// trip seeds with this trip's data and drifts gracefully across the
/// fleet of trips for that vehicle.
@immutable
class GearInferenceResult {
  /// Per-sample inferred gears, in the same order as the input
  /// samples. `gear == null` for samples that were skipped (idle,
  /// outlier, or — when no centroids could be computed — every
  /// sample).
  final List<InferredGearSample> samples;

  /// Cluster centroids in ratio space, sorted ascending. Centroid at
  /// index 0 corresponds to the top gear (e.g. 5th in a 5-speed);
  /// centroid at index `length - 1` corresponds to 1st gear. Empty
  /// when no valid samples were found (idle-only / no-data trips).
  final List<double> centroids;

  const GearInferenceResult({required this.samples, required this.centroids});
}

/// Internal: minimum speed (km/h) below which a sample is treated as
/// idle / sub-threshold and skipped from clustering. The wheel-speed
/// sensor on most cars is unreliable below ~5 km/h, and the resulting
/// ratio inflates without bound.
const double _minSpeedKmh = 5.0;

/// Internal: minimum RPM below which a sample is treated as idle /
/// engine-off and skipped. 500 RPM is well below any production
/// engine's idle (which sits at 700–900) yet above the noise floor.
const double _minRpm = 500.0;

/// Internal: maximum k-means iterations. 1-D k-means converges fast;
/// 10 is generous for trips with ~600 samples.
const int _maxIterations = 10;

/// Internal: relative centroid-shift threshold for early stopping.
/// 0.5 % is well below the inter-gear separation on every
/// transmission we've measured.
const double _convergenceEpsilon = 0.005;

/// Infer per-sample gears from a sequence of [TripSample]s using the
/// engine-RPM / wheel-RPM ratio (gear-correlated drivetrain ratio).
///
/// See the library docstring for the formula, the heuristic
/// thresholds (idle skip, outlier trim) and the convention that
/// maps a centroid index to a human-readable gear label.
///
/// [tireCircumferenceMeters] is per-vehicle (≈ 1.95 m for a typical
/// 195/65R15). [priorCentroids] (optional) seeds the clustering with
/// centroids learned on a previous trip — the algorithm will allow
/// drift toward this trip's data, so the cache improves
/// trip-over-trip without overwriting a stable baseline. When null,
/// the algorithm cold-starts from this trip's percentiles.
/// [targetGearCount] is the number of distinct gear clusters to
/// seek; defaults to 5 for a typical 5-speed manual.
///
/// Throws nothing for any well-formed input — degenerate fixtures
/// (idle-only, < `targetGearCount` valid samples) return as best
/// they can with empty / partial centroid lists.
GearInferenceResult inferGears({
  required Iterable<TripSample> samples,
  required double tireCircumferenceMeters,
  List<double>? priorCentroids,
  int targetGearCount = 5,
}) {
  // Materialise the iterable once; we walk it twice (extract ratios,
  // then re-label every sample including the skipped ones).
  final sampleList = samples.toList(growable: false);

  // Defensive: a non-positive tyre circumference would invert the
  // formula. Treat as "no inference possible" — return all-null
  // gears, no centroids, no exception. The caller (phase 2 trip
  // recorder) is expected to validate the per-vehicle profile
  // before calling, but we don't trust upstream.
  if (tireCircumferenceMeters <= 0 || targetGearCount < 1) {
    return GearInferenceResult(
      samples: sampleList
          .map((s) => InferredGearSample(timestamp: s.timestamp, gear: null))
          .toList(growable: false),
      centroids: const <double>[],
    );
  }

  // First pass: derive (sampleIndex, ratio) pairs that pass the
  // idle-skip rule. We keep the index so we can re-label without a
  // second filter pass later.
  final validIndices = <int>[];
  final validRatios = <double>[];
  for (var i = 0; i < sampleList.length; i++) {
    final s = sampleList[i];
    if (s.speedKmh < _minSpeedKmh || s.rpm < _minRpm) {
      continue;
    }
    final wheelRpm = (s.speedKmh / 3.6) / tireCircumferenceMeters * 60.0;
    if (wheelRpm <= 0) {
      // Speed passed the threshold but the formula still degenerated;
      // treat as a skip rather than throw.
      continue;
    }
    final ratio = s.rpm / wheelRpm;
    if (!ratio.isFinite || ratio <= 0) {
      continue;
    }
    validIndices.add(i);
    validRatios.add(ratio);
  }

  // No valid samples → return all-null gears and empty centroids.
  // Idle-only fixtures (test 4) land here.
  if (validRatios.isEmpty) {
    return GearInferenceResult(
      samples: sampleList
          .map((s) => InferredGearSample(timestamp: s.timestamp, gear: null))
          .toList(growable: false),
      centroids: const <double>[],
    );
  }

  // Outlier trim: drop ratios above 99th × 2 or below 1st / 2. We
  // build the percentile bracket on the surviving ratios so a small
  // fixture (test 5) doesn't immediately throw away most of its data.
  final sortedRatios = List<double>.from(validRatios)..sort();
  final p1 = _percentile(sortedRatios, 0.01);
  final p99 = _percentile(sortedRatios, 0.99);
  final lowerBound = p1 / 2.0;
  final upperBound = p99 * 2.0;

  final keptIndices = <int>[];
  final keptRatios = <double>[];
  for (var j = 0; j < validRatios.length; j++) {
    final r = validRatios[j];
    if (r < lowerBound || r > upperBound) continue;
    keptIndices.add(validIndices[j]);
    keptRatios.add(r);
  }

  if (keptRatios.isEmpty) {
    return GearInferenceResult(
      samples: sampleList
          .map((s) => InferredGearSample(timestamp: s.timestamp, gear: null))
          .toList(growable: false),
      centroids: const <double>[],
    );
  }

  // Seed centroids. With priorCentroids → reuse + drift; without →
  // sample uniform quantiles of the kept ratios so the seeds span
  // the data evenly.
  final keptSorted = List<double>.from(keptRatios)..sort();
  final centroids = <double>[];
  if (priorCentroids != null && priorCentroids.isNotEmpty) {
    centroids.addAll(priorCentroids);
    centroids.sort();
  } else {
    for (var k = 0; k < targetGearCount; k++) {
      // (2k + 1) / (2 * targetGearCount): for targetGearCount = 5
      // this hits 0.1, 0.3, 0.5, 0.7, 0.9 — i.e. the 10th / 30th /
      // 50th / 70th / 90th percentiles, as documented.
      final q = (2.0 * k + 1.0) / (2.0 * targetGearCount);
      centroids.add(_percentile(keptSorted, q));
    }
  }

  // Centroid de-duplication: a degenerate fixture (test 5 — only 5
  // samples total) will produce repeated quantile picks. K-means
  // tolerates this — clusters with no assigned points keep their
  // seed value — but we still return a sorted list so the contract
  // holds.
  centroids.sort();

  // K-means iterations.
  final assignments = List<int>.filled(keptRatios.length, 0);
  for (var iter = 0; iter < _maxIterations; iter++) {
    // Assignment step.
    for (var j = 0; j < keptRatios.length; j++) {
      assignments[j] = _nearestCentroid(centroids, keptRatios[j]);
    }
    // Update step.
    final newCentroids = List<double>.from(centroids);
    final sums = List<double>.filled(centroids.length, 0.0);
    final counts = List<int>.filled(centroids.length, 0);
    for (var j = 0; j < keptRatios.length; j++) {
      final c = assignments[j];
      sums[c] += keptRatios[j];
      counts[c]++;
    }
    for (var c = 0; c < centroids.length; c++) {
      if (counts[c] > 0) {
        newCentroids[c] = sums[c] / counts[c];
      }
      // counts[c] == 0 → keep the prior seed; the cluster is empty
      // this iteration.
    }
    // Convergence check: max relative shift across the centroids.
    var maxRelShift = 0.0;
    for (var c = 0; c < centroids.length; c++) {
      final base = centroids[c].abs();
      if (base <= 0) continue;
      final shift = (newCentroids[c] - centroids[c]).abs() / base;
      if (shift > maxRelShift) maxRelShift = shift;
    }
    for (var c = 0; c < centroids.length; c++) {
      centroids[c] = newCentroids[c];
    }
    if (maxRelShift < _convergenceEpsilon) {
      break;
    }
  }

  // Final assignment after the last update; the loop's last
  // iteration updated centroids but didn't reassign — re-do it so
  // the per-sample labels reflect the final centroid positions.
  centroids.sort();
  for (var j = 0; j < keptRatios.length; j++) {
    assignments[j] = _nearestCentroid(centroids, keptRatios[j]);
  }

  // Build the per-sample output. Skipped samples carry gear=null;
  // kept samples carry the human-readable gear label
  // (`targetGearCount - centroidIndex`) — see library docs.
  final inferredByOriginalIndex = <int, int>{};
  for (var j = 0; j < keptIndices.length; j++) {
    final centroidIndex = assignments[j];
    final gearLabel = targetGearCount - centroidIndex;
    inferredByOriginalIndex[keptIndices[j]] = gearLabel;
  }

  final out = <InferredGearSample>[];
  for (var i = 0; i < sampleList.length; i++) {
    out.add(InferredGearSample(
      timestamp: sampleList[i].timestamp,
      gear: inferredByOriginalIndex[i],
    ));
  }

  return GearInferenceResult(
    samples: List<InferredGearSample>.unmodifiable(out),
    centroids: List<double>.unmodifiable(centroids),
  );
}

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

    final dt = next.timestamp.difference(current.timestamp).inMicroseconds /
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

/// Internal: linear-interpolation percentile on a pre-sorted list.
/// `q` in `[0, 1]`. Returns the only element for length-1 inputs and
/// the boundary element for `q <= 0` / `q >= 1`. Used to seed
/// centroids and to bracket outliers.
double _percentile(List<double> sortedAscending, double q) {
  if (sortedAscending.isEmpty) {
    return 0.0;
  }
  if (sortedAscending.length == 1) {
    return sortedAscending[0];
  }
  if (q <= 0) return sortedAscending.first;
  if (q >= 1) return sortedAscending.last;
  final pos = q * (sortedAscending.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  if (lo == hi) return sortedAscending[lo];
  final frac = pos - lo;
  return sortedAscending[lo] + (sortedAscending[hi] - sortedAscending[lo]) * frac;
}

/// Internal: index of the centroid nearest to [value] in 1-D
/// (Euclidean distance reduces to absolute difference). Ties go to
/// the lower index — k-means is stable across iterations because
/// the centroids' positions evolve smoothly and ties occur measure-
/// zero in practice.
int _nearestCentroid(List<double> centroids, double value) {
  var bestIndex = 0;
  var bestDistance = (centroids[0] - value).abs();
  for (var c = 1; c < centroids.length; c++) {
    final d = (centroids[c] - value).abs();
    if (d < bestDistance) {
      bestDistance = d;
      bestIndex = c;
    }
  }
  return bestIndex;
}

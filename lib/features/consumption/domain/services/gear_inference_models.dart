/// Value objects for the gear-inference pipeline (#1263 phase 1).
///
/// Split out of `gear_inference.dart` to keep that file under the
/// 300-LOC budget (Refs #563). Both classes remain in the same library
/// via `part of` — no public API surface changes; existing imports of
/// `gear_inference.dart` continue to resolve `InferredGearSample` and
/// `GearInferenceResult` without churn.
part of 'gear_inference.dart';

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

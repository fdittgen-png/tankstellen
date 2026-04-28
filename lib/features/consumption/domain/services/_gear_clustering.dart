/// Internal clustering helpers for the gear-inference pipeline
/// (#1263 phase 1).
///
/// Split out of `gear_inference.dart` to keep that file under the
/// 300-LOC budget (Refs #563). Library-private (`part of`) — no public
/// API surface changes. The helpers here are pure 1-D maths utilities;
/// the main `inferGears` orchestrator in the parent file owns the
/// idle-skip / outlier-trim / labelling concerns.
part of 'gear_inference.dart';

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
  return sortedAscending[lo] +
      (sortedAscending[hi] - sortedAscending[lo]) * frac;
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

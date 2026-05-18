/// A road grade (slope) estimate with a confidence flag (#1941).
class RoadGrade {
  /// Signed grade as a rise/run fraction — positive uphill, negative
  /// downhill. `0.05` is a 5 % climb.
  final double gradeFraction;

  /// Whether the estimate is trustworthy enough to feed into the fuel
  /// model. False until a full distance window of reasonably dense
  /// altitude samples has accumulated; callers treat a non-confident
  /// grade as flat road (0).
  final bool confident;

  const RoadGrade({required this.gradeFraction, required this.confident});

  /// The neutral "flat road / don't know" value.
  static const RoadGrade flat = RoadGrade(gradeFraction: 0, confident: false);
}

/// Computes a smoothed road grade from a stream of GPS altitude +
/// distance samples (#1941, epic #1935 child B).
///
/// Phone GPS altitude is noisy — ±10–30 m per fix — so differencing it
/// sample-to-sample yields meaningless grades. This calculator instead:
///
///  * **exponentially smooths** altitude before using it, which damps
///    the per-fix random error;
///  * measures grade over a distance **window** ([windowMeters]), where
///    the residual-noise-to-window ratio is small (a ±3 m residual over
///    a 150 m window is a 2 % grade error);
///  * reports a **confidence** — the grade is only [RoadGrade.confident]
///    once a full window of reasonably dense samples exists. A stretch
///    with no GPS altitude thins the window out and drops confidence.
///
/// Pure logic — no Flutter / plugin dependency, fully unit-testable.
/// The caller (#1942) feeds it the trip's running distance + the GPS
/// altitude latched on each [TripSample] (#1940), and applies the grade
/// to the speed-density fuel estimate only when it is confident.
class RoadGradeCalculator {
  RoadGradeCalculator({
    this.windowMeters = 150.0,
    this.smoothingFactor = 0.2,
    this.minSamplesInWindow = 5,
  })  : assert(windowMeters > 0),
        assert(smoothingFactor > 0 && smoothingFactor <= 1),
        assert(minSamplesInWindow >= 2);

  /// Distance (metres) the grade is measured over. Longer = less
  /// noise-sensitive but slower to react to a real slope change.
  final double windowMeters;

  /// Exponential-smoothing factor for altitude (0..1]. Lower is
  /// smoother (more noise rejection, more lag).
  final double smoothingFactor;

  /// Minimum smoothed samples that must fall inside the window for the
  /// grade to be [RoadGrade.confident] — guards against a sparse
  /// window left by a GPS-altitude dropout.
  final int minSamplesInWindow;

  final List<_GradePoint> _points = <_GradePoint>[];
  double? _smoothedAltitudeM;

  /// Feed one sample. [cumulativeDistanceKm] is the trip's total
  /// distance so far (monotonically non-decreasing); [altitudeM] is the
  /// GPS altitude in metres, or null when no fix is available — a null
  /// adds no point, so a run of nulls thins the window and lowers
  /// confidence.
  void addSample({
    required double cumulativeDistanceKm,
    double? altitudeM,
  }) {
    if (altitudeM == null) return;
    final distanceM = cumulativeDistanceKm * 1000.0;
    final previous = _smoothedAltitudeM;
    final smoothed = previous == null
        ? altitudeM
        : smoothingFactor * altitudeM + (1 - smoothingFactor) * previous;
    _smoothedAltitudeM = smoothed;
    _points.add(_GradePoint(distanceM, smoothed));
    // Keep memory bounded — nothing past 2x the window is ever read.
    final cutoff = distanceM - windowMeters * 2;
    _points.removeWhere((p) => p.distanceM < cutoff);
  }

  /// The current grade estimate over the trailing [windowMeters].
  RoadGrade get current {
    if (_points.length < 2) return RoadGrade.flat;
    final latest = _points.last;

    // The anchor is the newest point at least a full window behind the
    // latest one — so `latest - anchor` spans ~windowMeters.
    _GradePoint? anchor;
    var samplesInWindow = 1; // the latest point itself
    for (final p in _points) {
      final back = latest.distanceM - p.distanceM;
      if (back >= windowMeters) {
        anchor = p;
      } else if (back > 0) {
        samplesInWindow++;
      }
    }
    if (anchor == null) return RoadGrade.flat;

    final run = latest.distanceM - anchor.distanceM;
    if (run <= 0) return RoadGrade.flat;
    final rise = latest.smoothedAltitudeM - anchor.smoothedAltitudeM;

    return RoadGrade(
      gradeFraction: rise / run,
      // A full window AND enough samples in it — a GPS-altitude
      // dropout leaves the window sparse and is not trusted.
      confident: samplesInWindow >= minSamplesInWindow,
    );
  }

  /// Drop all accumulated state — call before recording a fresh trip.
  void reset() {
    _points.clear();
    _smoothedAltitudeM = null;
  }
}

class _GradePoint {
  final double distanceM;
  final double smoothedAltitudeM;
  const _GradePoint(this.distanceM, this.smoothedAltitudeM);
}

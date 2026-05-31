// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';
import 'dart:math' as math;

import '../data/obd2/trip_live_reading.dart';
import 'road_grade_calculator.dart';

/// One timestamped speed reading in the rolling stop-and-go window
/// (#2513). Kept private — callers only need the derived flag / accel.
class _SpeedPoint {
  final DateTime at;
  final double speedKmh;
  const _SpeedPoint(this.at, this.speedKmh);
}

/// Altitude band a learned baseline is stratified under (#2515, epic
/// #2512). Air density falls with altitude, so the same driving
/// situation burns differently at sea level vs in the mountains;
/// keying each Welford bucket by `'${situation.name}#$id'` keeps the
/// bands from averaging together.
///
/// The [id] strings are the stable on-disk suffix — they must never
/// change (they're baked into Hive keys). [BaselineStore] composes the
/// key; legacy bare keys (pre-#2515) are read back as [seaLevel].
enum BaselineAltitudeStratum {
  /// ≤ 500 m — also the fallback for legacy data and for trips with no
  /// confident altitude / baro fix.
  seaLevel('alt0'),

  /// 500–1000 m.
  low('alt500'),

  /// 1000–1500 m.
  mid('alt1000'),

  /// > 1500 m.
  high('alt1500p');

  const BaselineAltitudeStratum(this.id);

  /// Stable on-disk suffix appended after `#` in the composite key.
  final String id;

  /// Pick the stratum for an altitude in metres. Null → [seaLevel] (the
  /// safe sea-level default while no confident fix exists).
  static BaselineAltitudeStratum forAltitudeM(double? altitudeM) {
    if (altitudeM == null) return seaLevel;
    if (altitudeM <= 500) return seaLevel;
    if (altitudeM <= 1000) return low;
    if (altitudeM <= 1500) return mid;
    return high;
  }

  /// Derive altitude from barometric pressure (kPa) via the barometric
  /// formula, then map to a stratum — the fallback when GPS altitude is
  /// unavailable but the car reports PID 0x33. `44330·(1−(p/101.325)^
  /// (1/5.255))`. Null baro → [seaLevel].
  static BaselineAltitudeStratum forBaroKpa(double? baroKpa) {
    if (baroKpa == null || baroKpa <= 0) return seaLevel;
    final altitudeM =
        44330.0 * (1 - math.pow(baroKpa / 101.325, 1 / 5.255));
    return forAltitudeM(altitudeM);
  }
}

/// Per-trip rolling state the fuzzy calibration path needs but the pure
/// [FuzzyClassifier] can't own (#2513, epic #2512).
///
/// The classifier is a pure function of one sample's inputs, yet two of
/// its situations are inherently *windowed*:
///
///  * **stop-and-go** is "low average speed with repeated start/stop
///    crossings over the last ~30 s" — a window feature, not an
///    instantaneous one;
///  * **decel** needs an acceleration, which is a finite difference
///    over recent speeds;
///  * **climbing** wants a *confident* road grade, which only emerges
///    once enough smoothed GPS-altitude samples accumulate over a
///    distance window.
///
/// Before #2513 the recorder passed `0` / `false` for all three, so the
/// stop-and-go and climbing buckets were permanently empty. This object
/// holds the rolling window + the [RoadGradeCalculator] and derives the
/// three signals, so [TripBaselineRecorder] just folds each reading in
/// and reads them back. Pure logic — fully unit-testable.
class BaselineRollingState {
  /// Width of the stop-and-go speed window. Mirrors the 30-s window the
  /// #894 ticket specifies for the caller-owned stop-and-go flag.
  static const Duration window = Duration(seconds: 30);

  /// Stop-and-go threshold on the standard deviation (km/h) of the
  /// rolling speed window. A steady cruise sits near 0; dense traffic
  /// with repeated starts/stops swings well past this.
  static const double stdDevThreshold = 3.0;

  final Queue<_SpeedPoint> _speedWindow = Queue<_SpeedPoint>();
  final RoadGradeCalculator _gradeCalc = RoadGradeCalculator();

  /// Latest barometric pressure (PID 0x33) seen this trip, latched for
  /// the altitude-stratum fallback when GPS altitude is unavailable.
  double? _latestBaroKpa;

  /// Fold one reading in: push its speed into the 30-s window (trimmed
  /// to [window] using [now]) and its distance + altitude into the
  /// grade calculator. A null altitude is a no-op for the grade (a run
  /// of nulls thins its window and drops confidence); a null speed is
  /// skipped for the speed window.
  void add(TripLiveReading r, DateTime now) {
    final speed = r.speedKmh;
    if (speed != null) {
      _speedWindow.addLast(_SpeedPoint(now, speed));
      while (_speedWindow.isNotEmpty &&
          now.difference(_speedWindow.first.at) > window) {
        _speedWindow.removeFirst();
      }
    }
    _gradeCalc.addSample(
      cumulativeDistanceKm: r.distanceKmSoFar,
      altitudeM: r.altitudeM,
    );
    if (r.baroKpa != null) _latestBaroKpa = r.baroKpa;
  }

  /// Drop all accumulated state — call at the start/end of each trip.
  void reset() {
    _speedWindow.clear();
    _gradeCalc.reset();
    _latestBaroKpa = null;
  }

  /// The altitude stratum (#2515) the current sample's baseline should
  /// be bucketed under. Prefers the smoothed GPS altitude from the
  /// grade calculator; falls back to the barometric estimate when no
  /// GPS fix has landed; defaults to sea level until either is
  /// confident — so a trip never starts writing into a wrong band.
  BaselineAltitudeStratum get altitudeStratum {
    final gpsAltitude = _gradeCalc.latestSmoothedAltitudeM;
    if (gpsAltitude != null) {
      return BaselineAltitudeStratum.forAltitudeM(gpsAltitude);
    }
    return BaselineAltitudeStratum.forBaroKpa(_latestBaroKpa);
  }

  /// The stable on-disk suffix for the current [altitudeStratum].
  String get altitudeStratumId => altitudeStratum.id;

  /// True when the rolling window looks like stop-and-go: either
  /// repeated start/stop crossings (≥2, mirroring [SituationClassifier]
  /// `_zeroSpeedCrossings`) OR a high speed standard deviation
  /// (> [stdDevThreshold]). Needs ≥3 samples so a single dip can't trip
  /// it.
  bool get isStopAndGoContext {
    if (_speedWindow.length < 3) return false;
    return _zeroSpeedCrossings() >= 2 || _speedStdDev() > stdDevThreshold;
  }

  /// Road grade as a percentage when the GPS-altitude estimate is
  /// confident, else 0 — so a non-confident grade falls back to flat
  /// and the load ramp carries the climbing bucket.
  double get confidentGradePct {
    final grade = _gradeCalc.current;
    return grade.confident ? grade.gradeFraction * 100 : 0;
  }

  /// Finite-difference acceleration (m/s²) over the trailing
  /// [windowSeconds] of the speed window, so the fuzzy path's decel
  /// membership has a real accel signal. 0 when fewer than two samples
  /// span the window.
  double recentAccelMps2({int windowSeconds = 3}) {
    if (_speedWindow.length < 2) return 0;
    final now = _speedWindow.last;
    _SpeedPoint? start;
    for (final p in _speedWindow) {
      if (now.at.difference(p.at).inSeconds <= windowSeconds) {
        start = p;
        break;
      }
    }
    start ??= _speedWindow.first;
    final dt = now.at.difference(start.at).inMilliseconds / 1000.0;
    if (dt <= 0) return 0;
    final dv = (now.speedKmh - start.speedKmh) / 3.6; // km/h → m/s
    return dv / dt;
  }

  /// The throttle signal the classifier should use: the real PID 0x11
  /// absolute throttle position when present, falling back to the
  /// calculated engine load only when throttle is unavailable (a coarse
  /// proxy that over-reads the closed-pedal state, which is why it
  /// can't be the primary signal). Null when neither is reported.
  static double? throttleSignal(TripLiveReading r) =>
      r.throttlePercent ?? r.engineLoadPercent;

  /// The load signal feeding the climbing/loaded load ramp: the
  /// wider-range absolute load (PID 0x43) when present, else calculated
  /// engine load (PID 0x04). 0 when neither is reported (the load ramp
  /// then contributes nothing and grade alone drives the bucket).
  static double loadSignal(TripLiveReading r) =>
      r.absLoadPercent ?? r.engineLoadPercent ?? 0;

  /// Coolant temperature below which the cold-start operating-temp gate
  /// considers the engine still warming up (PID 0x05). Matches the warm
  /// shoulder of the fuzzy [FuzzyClassifier] cold-start ramp.
  static const double warmUpCoolantCeilingC = 70;

  /// Oil-temperature fallback ceiling when coolant is unavailable
  /// (PID 0x5C). Lower than the coolant ceiling because oil lags
  /// coolant and reaches operating temperature a little cooler.
  static const double warmUpOilCeilingC = 50;

  /// True while the engine is below operating temperature (#2515): the
  /// belt-and-braces warm-up gate the recorder uses to *guarantee* a
  /// cold sample only feeds the cold-start bucket, independent of the
  /// fuzzy classifier's own cold-start override. Prefers coolant
  /// (< [warmUpCoolantCeilingC]); falls back to oil
  /// (< [warmUpOilCeilingC]) when coolant is null; false when neither
  /// temperature is reported (no evidence of a cold start).
  static bool isWarmUp(TripLiveReading r) {
    final coolant = r.coolantTempC;
    if (coolant != null) return coolant < warmUpCoolantCeilingC;
    final oil = r.oilTempC;
    if (oil != null) return oil < warmUpOilCeilingC;
    return false;
  }

  /// Stoichiometry-normalising fuel-mass correction (#2515).
  ///
  /// Two samples taken at different commanded mixtures (open-loop
  /// enrichment, fuel-trim corrections, or different air density) inject
  /// different fuel masses for the *same* underlying demand, so a raw
  /// fuel-rate baseline blends regimes that aren't comparable. This pure
  /// factor renormalises each sample's value back to the stoichiometric,
  /// sea-level-density demand BEFORE it feeds the Welford accumulator, so
  /// a bucket learns the true per-situation demand instead of an average
  /// of mixtures.
  ///
  /// `factor = λterm × trimterm × densityterm`. Each term degrades to
  /// **1.0** when its PID is null, so a car that surfaces none of these
  /// signals sees exactly today's behaviour — no regression:
  ///
  ///  * **λ-term** ([TripLiveReading.lambda], PID 0x44 commanded
  ///    equivalence ratio φ = AFR/AFR_stoich): `λ` when `λ ∈ [0.5, 1.5]`,
  ///    else 1.0. Enrichment (`λ < 1`) injects extra fuel for the same
  ///    air charge, so scaling the measured rate *down* by λ divides that
  ///    extra fuel back out and leaves the stoichiometric demand; a lean
  ///    cruise (`λ > 1`) scales the other way. (An enriched λ=0.9 sample
  ///    therefore yields a sub-1.0 factor → a lower learned mean than the
  ///    raw rate, which is the precision win.)
  ///  * **trim-term** ([TripLiveReading.stft] PID 0x06 +
  ///    [TripLiveReading.ltft] PID 0x07, each −20..+20 %):
  ///    `(1 + (stft + ltft) / 100)`, clamped to `[0.7, 1.3]` so a
  ///    glitchy trim reading can't dominate.
  ///  * **density-term** ([TripLiveReading.mapKpa], PID 0x0B intake
  ///    manifold absolute pressure as an air-density proxy):
  ///    `clamp(mapKpa / 100, 0.6, 1.2)`.
  static double fuelMassCorrectionFactor(TripLiveReading r) {
    return _lambdaTerm(r.lambda) *
        _trimTerm(r.stft, r.ltft) *
        _densityTerm(r.mapKpa);
  }

  /// λ-term: scale the measured rate by λ so commanded enrichment
  /// (λ < 1, extra fuel) is divided back out and the baseline reflects
  /// stoichiometric demand. Identity outside the plausible `[0.5, 1.5]`
  /// band (or when PID 0x44 is absent).
  static double _lambdaTerm(double? lambda) {
    if (lambda == null) return 1;
    if (lambda < 0.5 || lambda > 1.5) return 1;
    return lambda;
  }

  /// trim-term: combined short+long fuel trim as a multiplicative
  /// correction, clamped so a transient spike can't swing the mean.
  /// Identity when both trims are absent.
  static double _trimTerm(double? stft, double? ltft) {
    if (stft == null && ltft == null) return 1;
    final combined = (stft ?? 0) + (ltft ?? 0);
    return (1 + combined / 100).clamp(0.7, 1.3);
  }

  /// density-term: intake-manifold pressure as an air-density proxy,
  /// clamped to a sane band. Identity when PID 0x0B is absent.
  static double _densityTerm(double? mapKpa) {
    if (mapKpa == null) return 1;
    return (mapKpa / 100).clamp(0.6, 1.2);
  }

  /// Count moving (>5 km/h) → stopped (≤1 km/h) transitions in the
  /// window. Mirrors [SituationClassifier]'s private heuristic so the
  /// two paths agree on what "stop-and-go" means.
  int _zeroSpeedCrossings() {
    var crossings = 0;
    var wasMoving = false;
    for (final p in _speedWindow) {
      if (p.speedKmh > 5) {
        wasMoving = true;
      } else if (p.speedKmh <= 1 && wasMoving) {
        crossings++;
        wasMoving = false;
      }
    }
    return crossings;
  }

  /// Standard deviation (km/h) of the speeds in the rolling window.
  double _speedStdDev() {
    final n = _speedWindow.length;
    if (n < 2) return 0;
    var mean = 0.0;
    for (final p in _speedWindow) {
      mean += p.speedKmh;
    }
    mean /= n;
    var sumSq = 0.0;
    for (final p in _speedWindow) {
      final d = p.speedKmh - mean;
      sumSq += d * d;
    }
    return math.sqrt(sumSq / (n - 1));
  }
}

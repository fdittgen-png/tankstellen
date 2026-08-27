// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../trips/api.dart';
import '../data/driving_score_calculator.dart';
import 'driving_score.dart';

/// The live driving-behaviour band shown while recording (#3845).
///
/// A 0..100 [score] over the last [LiveDrivingBandTracker.window] of
/// driving plus the [DrivingStyleClass] it falls into — the four bands
/// the recording screen paints green / yellow / orange / red.
class LiveDrivingBand {
  /// 0..100, same scale and meaning as the end-of-trip driving score.
  final int score;

  /// Coarse band, via the shared [DrivingStyleClass.fromScore] cut-offs.
  final DrivingStyleClass styleClass;

  const LiveDrivingBand({required this.score, required this.styleClass});

  @override
  bool operator ==(Object other) =>
      other is LiveDrivingBand &&
      other.score == score &&
      other.styleClass == styleClass;

  @override
  int get hashCode => Object.hash(score, styleClass);
}

/// Rolling driving-behaviour band for the live recording surfaces
/// (#3845).
///
/// The end-of-trip driving score answers "how was that drive?"; this
/// answers "how am I driving *right now*?" — so it runs the SAME
/// [computeDrivingScore] over a sliding [window] of the most recent
/// samples instead of the whole trip. Reusing the canonical calculator
/// is deliberate: #2460 collapsed two divergent 0..100 implementations
/// into one, and a bespoke live scorer would immediately re-open that
/// split, letting the live colour disagree with the score the driver
/// reads on the trip afterwards.
///
/// Cost is bounded on both axes: the window holds at most
/// `window / emit cadence` samples (≈360 at 90 s / 4 Hz) and the score
/// is recomputed at most once per [recomputeInterval], so the emit loop
/// pays one ~360-step pass per second regardless of trip length.
///
/// The tracker takes primitives rather than a built `TripSample` so the
/// caller can feed it the *effective* speed (OBD2 PID or the GPS
/// fallback). That is what makes the band "always on": a GPS-only
/// trajet has no rpm or throttle, and the speed-derived penalties
/// (hard accel / hard brake / smoothness / speed efficiency) carry the
/// score on their own, while the engine-only penalties contribute 0.
///
/// Pure state machine — no timers, no I/O; the caller supplies the
/// clock. One instance per recording.
class LiveDrivingBandTracker {
  LiveDrivingBandTracker({
    this.window = const Duration(seconds: 90),
    this.recomputeInterval = const Duration(seconds: 1),
    this.minSamples = 8,
    this.minSpan = const Duration(seconds: 15),
  });

  /// How far back the rolling score looks. 90 s is long enough that one
  /// junction does not repaint the whole card, short enough that the
  /// colour still answers "right now" rather than "this trip".
  final Duration window;

  /// Lower bound between two recomputations. The emit loop ticks at
  /// 4 Hz; scoring on every tick would be 4× the work for a number the
  /// eye cannot follow anyway.
  final Duration recomputeInterval;

  /// Samples required before a band is published at all.
  final int minSamples;

  /// Elapsed driving required before a band is published.
  ///
  /// [computeDrivingScore] returns a perfect 100 for a degenerate
  /// window, so publishing immediately would flash a confident green in
  /// the first second of every trip and then fall — the band would be
  /// reporting "no data yet" in the colour that means "driving well".
  final Duration minSpan;

  final List<TripSample> _recent = <TripSample>[];
  DateTime? _lastComputedAt;
  LiveDrivingBand? _band;

  /// The most recently computed band, or null while the tracker is
  /// still filling [minSamples] / [minSpan].
  LiveDrivingBand? get band => _band;

  /// Samples currently inside the window. Exposed for tests.
  int get windowSampleCount => _recent.length;

  /// Fold one emit tick in and return the current band (possibly the
  /// previous one, when this tick did not trigger a recomputation).
  ///
  /// [suppressSpeedHarsh] threads the #2653 provenance guard: on a
  /// dead-reckoned (`virtual`) distance source the speed series is
  /// synthesised, and scoring harsh events off it invents behaviour the
  /// driver never exhibited.
  LiveDrivingBand? add({
    required DateTime at,
    required double speedKmh,
    double? rpm,
    double? throttlePercent,
    double? engineLoadPercent,
    double? fuelRateLPerHour,
    bool suppressSpeedHarsh = false,
  }) {
    // A clock that jumped backwards would corrupt every Δt in the
    // window; drop the whole window and restart rather than score it.
    final previous = _recent.isEmpty ? null : _recent.last.timestamp;
    if (previous != null && at.isBefore(previous)) {
      reset();
    }

    _recent.add(TripSample(
      timestamp: at,
      speedKmh: speedKmh,
      rpm: rpm,
      throttlePercent: throttlePercent,
      engineLoadPercent: engineLoadPercent,
      fuelRateLPerHour: fuelRateLPerHour,
    ));
    final cutoff = at.subtract(window);
    _recent.removeWhere((s) => s.timestamp.isBefore(cutoff));

    final last = _lastComputedAt;
    if (last != null && at.difference(last) < recomputeInterval) return _band;
    if (_recent.length < minSamples) return _band;
    if (at.difference(_recent.first.timestamp) < minSpan) return _band;

    _lastComputedAt = at;
    final score = computeDrivingScore(
      _recent,
      suppressSpeedHarsh: suppressSpeedHarsh,
    );
    return _band = LiveDrivingBand(
      score: score.score,
      styleClass: score.styleClass,
    );
  }

  /// Drop the window and the published band.
  void reset() {
    _recent.clear();
    _lastComputedAt = null;
    _band = null;
  }
}

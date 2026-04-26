/// Time-share histogram calculator for the throttle / RPM card on the
/// Trip detail screen (#1041 phase 3a — "Card C").
///
/// Pure-Dart, no async, no platform deps. Takes a chronological list of
/// throttle / RPM samples (one per OBD2 polling tick — typically ~1 Hz)
/// and returns the share of time the driver spent in each band, per
/// axis. The presentation layer (`ThrottleRpmHistogramCard`) renders
/// the result as two simple bar groups.
///
/// ## Why "time-share" and not "sample count"?
///
/// OBD2 cadence drifts with adapter chatter — counting samples would
/// double-weight ticks that landed back-to-back during a fast scan
/// window. We integrate the dt between consecutive samples instead so
/// the histogram reflects how long the driver spent at each throttle /
/// RPM, not how often the adapter happened to emit. This mirrors the
/// approach in `trip_recorder.dart` and `driving_insights_analyzer.dart`
/// — the histogram should match the "12% of trip" copy on the
/// driving-insights card right above it.
///
/// ## Band edges
///
/// **Throttle quartiles** (in absolute throttle %):
///   * 0–25 %   — coast / closed throttle
///   * 25–50 %  — light cruise
///   * 50–75 %  — firm pedal
///   * 75–100 % — wide-open / kick-down
///
/// Even quartiles keep the bar groups easy to read; quartiles also map
/// cleanly to the eco-feedback bucket already used in
/// `lib/features/vehicle/domain/fuzzy_classifier.dart` (which checks
/// `throttle > 50` for hard-accel detection — our 50 % quartile boundary
/// lines up with that signal).
///
/// **RPM bands** (in absolute RPM):
///   * idle      ≤ 900    — engine on, drivetrain disengaged
///   * cruise    901–2000 — typical highway / boulevard cruise
///   * spirited  2001–3000 — accelerating, lower gear, towing
///   * hard      > 3000   — high-RPM zone (matches the analyzer's
///                          `_highRpmThreshold = 3000` so this card and
///                          the "Engine over 3000 RPM" insight on the
///                          same screen tell a consistent story)
///
/// The bands intentionally diverge from `TripRecorder.highRpmThreshold`
/// (3500) — the recorder's "high-RPM seconds" stat tolerates a slightly
/// higher threshold to feel less alarmist; the histogram surfaces the
/// same coaching-grade `3000` cut that the cost-line card uses.
///
/// ## Edge cases
///
/// * Empty input → all-zero histograms (each band returns 0.0). The
///   widget renders an empty-state hint in that case.
/// * Single sample → all-zero histograms. We need at least one valid
///   `dt` between two samples to weight a bucket; a single sample has
///   no duration.
/// * Null throttle / RPM in a sample → that sample's interval is
///   skipped on the relevant axis only. Throttle nulls do not erase
///   RPM weight, and vice versa — older trips carry RPM but no
///   throttle (PID 11 wasn't in the polling rotation), so we still
///   want to show the RPM histogram for them.
/// * Non-monotonic timestamps → intervals with `dt <= 0` are skipped
///   (matches the recorder's behaviour for out-of-order samples).
library;

import 'package:flutter/foundation.dart';

/// One throttle / RPM tick fed into [calculateThrottleRpmHistogram].
///
/// Mirrors the timestamped shape of `TripSample` / `TripDetailSample`
/// but lives next to the calculator so the domain layer's
/// time-series entities stay focused on what's actually persisted on
/// disk. The calculator's caller adapts whichever real entity it has
/// (live recording snapshot, persisted history sample, hand-built
/// fixture) into a list of these.
@immutable
class ThrottleRpmSample {
  /// Sample timestamp. Used to derive the duration to the NEXT sample
  /// — that interval is what gets weighted into a bucket.
  final DateTime timestamp;

  /// Absolute throttle position, 0–100 %. Null when the OBD2 adapter
  /// hasn't surfaced PID 11 for this tick (legacy trips, or a tick
  /// that landed before the 5 Hz throttle subscription warmed up).
  final double? throttlePercent;

  /// Engine RPM, 0+. Null when the car's PID cache flagged RPM as
  /// unsupported (rare; almost every vehicle reports PID 0C).
  final double? rpm;

  const ThrottleRpmSample({
    required this.timestamp,
    this.throttlePercent,
    this.rpm,
  });
}

/// Result of [calculateThrottleRpmHistogram] — two histograms, one per
/// axis, each as four time-share fractions in `[0, 1]` summing to
/// `1.0` when at least one valid interval was processed for that axis,
/// or `0.0` when the input had no usable samples on that axis.
@immutable
class ThrottleRpmHistogram {
  /// Time-share of the trip with throttle in each quartile, in order:
  /// `[0–25 %, 25–50 %, 50–75 %, 75–100 %]`. Each entry is in `[0, 1]`.
  final List<double> throttleQuartiles;

  /// Time-share of the trip with RPM in each band, in order:
  /// `[idle, cruise, spirited, hard]`. Each entry is in `[0, 1]`.
  final List<double> rpmBands;

  const ThrottleRpmHistogram({
    required this.throttleQuartiles,
    required this.rpmBands,
  });

  /// All-zero histogram. Used by the calculator for empty / single-
  /// sample input, and exposed publicly so the widget can pre-render
  /// an empty state without depending on the calculator.
  static const ThrottleRpmHistogram empty = ThrottleRpmHistogram(
    throttleQuartiles: <double>[0.0, 0.0, 0.0, 0.0],
    rpmBands: <double>[0.0, 0.0, 0.0, 0.0],
  );

  /// Whether either axis carries any time-share. Used by the widget to
  /// decide between "render bars" and "render empty-state hint".
  bool get hasData {
    for (final q in throttleQuartiles) {
      if (q > 0) return true;
    }
    for (final b in rpmBands) {
      if (b > 0) return true;
    }
    return false;
  }
}

/// Compute the throttle quartile + RPM band time-share histograms over
/// [samples]. See the library-level docs for band edges and edge-case
/// behaviour.
///
/// Implementation: walk consecutive sample pairs and credit the
/// duration `dt = next.timestamp - sample.timestamp` to whichever
/// bucket the START sample's value falls into. The trailing sample
/// has no successor and is therefore not weighted on its own — the
/// loop runs `samples.length - 1` times. This mirrors the analyzer's
/// `prev.rpm > threshold` accounting so the two cards on the screen
/// agree on what "12 %" means.
///
/// Time complexity: O(n). No allocation per sample beyond the four
/// running accumulators.
ThrottleRpmHistogram calculateThrottleRpmHistogram(
  List<ThrottleRpmSample> samples,
) {
  if (samples.length < 2) {
    return ThrottleRpmHistogram.empty;
  }

  // Per-axis accumulators in seconds. Kept separate so a sample with
  // a null throttle but a valid RPM still contributes to the RPM
  // histogram (and vice versa).
  final throttleSeconds = <double>[0.0, 0.0, 0.0, 0.0];
  final rpmSeconds = <double>[0.0, 0.0, 0.0, 0.0];
  double throttleTotal = 0.0;
  double rpmTotal = 0.0;

  for (int i = 0; i < samples.length - 1; i++) {
    final start = samples[i];
    final next = samples[i + 1];
    final dt = next.timestamp.difference(start.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) {
      // Out-of-order or duplicate timestamp — skip, matching the
      // recorder's defensive behaviour.
      continue;
    }

    final throttle = start.throttlePercent;
    if (throttle != null) {
      throttleSeconds[_throttleQuartileIndex(throttle)] += dt;
      throttleTotal += dt;
    }

    final rpm = start.rpm;
    if (rpm != null) {
      rpmSeconds[_rpmBandIndex(rpm)] += dt;
      rpmTotal += dt;
    }
  }

  return ThrottleRpmHistogram(
    throttleQuartiles: _normalize(throttleSeconds, throttleTotal),
    rpmBands: _normalize(rpmSeconds, rpmTotal),
  );
}

/// Map an absolute throttle % to its quartile index (0..3).
///
/// Boundaries: `[0, 25)`, `[25, 50)`, `[50, 75)`, `[75, ∞)`. Values
/// outside `[0, 100]` (impossible on a real OBD2 stream but cheap to
/// defend against) are clamped — negative throttle goes to bucket 0,
/// over-100 % goes to bucket 3.
int _throttleQuartileIndex(double throttle) {
  if (throttle < 25.0) return 0;
  if (throttle < 50.0) return 1;
  if (throttle < 75.0) return 2;
  return 3;
}

/// Map an absolute RPM to its band index (0..3): `idle / cruise /
/// spirited / hard`. See library docs for band edges. The boundaries
/// use exclusive upper bounds so a steady 900 RPM idle counts as
/// idle, not cruise.
int _rpmBandIndex(double rpm) {
  if (rpm <= 900.0) return 0;
  if (rpm <= 2000.0) return 1;
  if (rpm <= 3000.0) return 2;
  return 3;
}

/// Normalize a per-bucket seconds array to a fractions array summing
/// to 1.0. Returns the all-zero list when [total] is zero so the
/// widget can detect "no data on this axis" without an extra flag.
List<double> _normalize(List<double> bucketSeconds, double total) {
  if (total <= 0) {
    return <double>[0.0, 0.0, 0.0, 0.0];
  }
  return <double>[
    bucketSeconds[0] / total,
    bucketSeconds[1] / total,
    bucketSeconds[2] / total,
    bucketSeconds[3] / total,
  ];
}

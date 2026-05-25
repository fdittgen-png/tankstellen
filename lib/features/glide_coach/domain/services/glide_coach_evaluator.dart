// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../entities/glide_coach_advice.dart';
import 'imminent_signal_detector.dart';

/// Default throttle threshold (percent, 0–100). The evaluator treats a
/// reading at or above this value as "user is on throttle" — a
/// pre-condition for the lift hint. 20 % sits above the typical
/// idle-creep throttle-by-wire reading so we don't hint while the user
/// is already off-pedal but coasting in gear.
const double kDefaultThrottleThresholdPercent = 20.0;

/// Default cool-down window after firing a `lift` advice. Long enough
/// that two close-spaced signals don't double-buzz, short enough that
/// a missed-then-corrected lift can re-fire on the next signal.
const Duration kDefaultGlideCoachCooldown = Duration(seconds: 15);

/// Correlates the [ImminentSignalDetector] output with the OBD2
/// throttle position to decide whether to suggest the user lift off
/// the accelerator (#1125 phase 3a).
///
/// Pure logic — no platform channels, no UI, no Riverpod state, no
/// haptic firing. The caller (phase 3b) is responsible for:
///   - throttling invocations (e.g. once per N seconds of GPS samples);
///   - gating on the user-facing setting toggle (`GlideCoachSettings.enabled`);
///   - translating a `GlideCoachAdvice.lift` into the actual
///     `HapticFeedback.lightImpact()` call.
///
/// ### Decision rules (first match wins)
///
/// 1. We fired `lift` within the last `cooldown` window → `cooldown`.
///    Cool-down is deliberate over-trigger suppression: the issue
///    explicitly demands a strict false-positive budget, and quiet
///    windows between buzzes are the cheapest way to hold the line
///    until the user-test cohort tunes the thresholds.
/// 2. `throttlePercent == null` (car has no PID 0x11 / sample dropped)
///    → `hold`. Under-trigger preference per the detector's existing
///    doctrine; never guess that throttle is high.
/// 3. `throttlePercent < throttleThresholdPercent` (already coasting)
///    → `hold`. Lifting advice while the user is already off-throttle
///    is noise.
/// 4. Detector returns `null` (no signal in the forward cone within
///    the horizon) → `hold`.
/// 5. Detector returned a signal → `lift`. Record the wall-clock time
///    so the next tick within `cooldown` short-circuits at rule 1.
///
/// ### Cool-down state machine
///
/// State is a single nullable `DateTime` of the last `lift`. Only
/// `lift` advices update the state; subsequent `cooldown` returns do
/// not extend the window (so a flurry of GPS ticks during the
/// cool-down does not push the next eligible buzz further out).
///
/// The injectable [now] callback lets tests advance "wall clock"
/// deterministically without `Future.delayed`.
class GlideCoachEvaluator {
  final ImminentSignalDetector _detector;
  final Duration _cooldown;
  final double _throttleThresholdPercent;
  final DateTime Function() _now;

  /// Wall-clock time of the most recent `lift` advice, or `null` when
  /// no advice has fired yet (or after a manual reset).
  DateTime? _lastLiftAt;

  GlideCoachEvaluator({
    required ImminentSignalDetector detector,
    Duration cooldown = kDefaultGlideCoachCooldown,
    double throttleThresholdPercent = kDefaultThrottleThresholdPercent,
    DateTime Function() now = DateTime.now,
  })  : _detector = detector,
        _cooldown = cooldown,
        _throttleThresholdPercent = throttleThresholdPercent,
        _now = now;

  /// Evaluate one tick. See the class doc for the 5-rule decision
  /// flow. The detector call is awaited; the caller throttles
  /// invocation cadence.
  Future<GlideCoachAdvice> evaluate({
    required GpsReading reading,
    required double? throttlePercent,
  }) async {
    // Rule 1 — cool-down short-circuit.
    final lastLift = _lastLiftAt;
    if (lastLift != null && _now().difference(lastLift) < _cooldown) {
      return GlideCoachAdvice.cooldown;
    }

    // Rule 2 — throttle data missing (car without PID 0x11).
    if (throttlePercent == null) return GlideCoachAdvice.hold;

    // Rule 3 — user already coasting.
    if (throttlePercent < _throttleThresholdPercent) {
      return GlideCoachAdvice.hold;
    }

    // Rule 4 — no signal ahead. The detector swallows repository
    // errors and returns null on its own (phase 2 contract); the
    // evaluator inherits that under-trigger preference for free.
    final signal = await _detector.nextSignalAhead(reading);
    if (signal == null) return GlideCoachAdvice.hold;

    // Rule 5 — fire and arm cool-down.
    _lastLiftAt = _now();
    return GlideCoachAdvice.lift;
  }
}

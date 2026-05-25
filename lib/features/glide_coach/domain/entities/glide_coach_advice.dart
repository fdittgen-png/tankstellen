// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The decision returned by [GlideCoachEvaluator] (#1125 phase 3a) for
/// a single GPS / throttle tick.
///
/// Pure data — no UI side-effects, no haptic call. Phase 3b maps these
/// values onto a `HapticFeedback.lightImpact()` call gated behind the
/// user-facing setting toggle. Until then the evaluator is dormant
/// behind `kGlideCoachEnabled = false`.
///
/// ### Why an enum (and not a Freezed sealed union)
///
/// The evaluator's caller in phase 3b only needs a tri-state branch
/// (`buzz` / `do nothing` / `do nothing because we just buzzed`). It
/// does not need to know which specific signal triggered the advice —
/// the detector keeps its own state and the user-test cohort scores
/// the buzz outcome, not the upstream geometry. A pure enum keeps the
/// surface tiny and avoids dragging build_runner / freezed into a
/// value type that has no JSON, no copyWith, and no equality concerns
/// beyond the language defaults.
enum GlideCoachAdvice {
  /// User is on throttle AND a red signal is imminent ahead. Phase 3b
  /// will translate this into a `HapticFeedback.lightImpact()` call.
  lift,

  /// No advice. One of:
  ///   - throttle data missing (car has no PID 0x11),
  ///   - user is already coasting (throttle below threshold),
  ///   - no signal within the forward cone / horizon.
  /// Under-trigger is the safe default for a distraction-warning
  /// feature; we never guess that the user is on throttle.
  hold,

  /// A `lift` was returned within the cool-down window. Suppress until
  /// the window expires. Cool-down is deliberate over-trigger
  /// suppression — the issue's acceptance criteria call for a strict
  /// false-positive budget and long quiet between buzzes is the
  /// cheapest way to hold the line until the user-test cohort tunes
  /// the thresholds.
  cooldown,
}

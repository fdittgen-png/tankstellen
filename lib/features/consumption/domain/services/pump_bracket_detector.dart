// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// The fuel-level bracket of a detected pump operation (#1619).
///
/// [startL] is the litres-in-tank just before the fill began; [endL]
/// the litres once the fill settled. [deltaL] is the dispensed volume —
/// what the verified-by-adapter badge cross-checks against the
/// user-typed litres.
@immutable
class PumpBracket {
  /// Litres in the tank immediately before the pump operation.
  final double startL;

  /// Litres in the tank immediately after the pump operation.
  final double endL;

  const PumpBracket({required this.startL, required this.endL});

  /// Dispensed volume — `endL - startL`. Always ≥ 0 by construction
  /// ([PumpBracketDetector] only completes a bracket on a net rise).
  double get deltaL => endL - startL;

  @override
  bool operator ==(Object other) =>
      other is PumpBracket &&
      other.startL == startL &&
      other.endL == endL;

  @override
  int get hashCode => Object.hash(startL, endL);

  @override
  String toString() => 'PumpBracket($startL L → $endL L, Δ$deltaL L)';
}

/// Brackets a pump operation from a stream of fuel-level readings by
/// its fuel-level *delta* — not by when the user opened or saved the
/// fill-up form (#1619, deferred from #1434).
///
/// ## Why
///
/// The MVP snapshots the tank level at form-open and form-submit. That
/// mis-captures the fill whenever the form lifecycle and the actual
/// pump operation don't line up:
///   * the user opens the form *before* fuelling → the "before" read
///     is already correct but a naive "after" read at submit can be
///     stale if they drove off first;
///   * the user opens the form *after* fuelling → the "before" read is
///     already the post-fill level.
///
/// Feeding every fuel-level reading through [observe] instead lets the
/// detector find the pump operation itself: a sharp net rise in tank
/// litres, bracketed by the stable level just before it and the peak
/// once it settles. The verified-by-adapter badge then reflects the
/// real fill regardless of form timing.
///
/// ## State machine
///
/// `beforeFill` → (a step-up rise) → `filling` → (level settles back
/// below the peak, or enough rise has accumulated) → `complete`.
///
/// A rise that never reaches [riseThresholdL] total is treated as
/// sensor noise / a slosh artefact and discarded — the detector
/// returns to `beforeFill`. The FIRST genuine fill wins; later rises
/// are ignored so a multi-stop journey doesn't overwrite the bracket.
///
/// The detector is pure and synchronous — it holds no streams and no
/// timers. The caller drives it: one [observe] call per fuel-level
/// reading, in chronological order.
class PumpBracketDetector {
  /// Minimum net rise (litres) for a bracket to count as a real fill.
  /// Below this the rise is discarded as noise. A genuine fill-up adds
  /// far more; the floor only rejects coarse-PID jitter.
  final double riseThresholdL;

  /// Minimum single-reading step-up (litres) that opens the `filling`
  /// phase. Filters the ±1 % jitter of a coarse `0x2F` percentage read.
  final double minStepL;

  /// How far below the running peak a reading must fall before the
  /// fill is considered settled (the car is being driven away).
  /// Tolerates a single noisy dip mid-fill.
  final double settleToleranceL;

  PumpBracketDetector({
    this.riseThresholdL = 2.0,
    this.minStepL = 1.0,
    this.settleToleranceL = 1.0,
  });

  _Phase _phase = _Phase.beforeFill;

  /// Running pre-fill level — the latest reading seen while no fill is
  /// in progress. Tracks down as the car is driven; becomes the
  /// bracket's [PumpBracket.startL] when a rise begins.
  double? _baseLevelL;

  /// Tank level captured the moment the current fill's rise started.
  double _startLevelL = 0;

  /// Highest level seen during the current fill.
  double _peakLevelL = 0;

  PumpBracket? _completed;

  /// Feed one fuel-level reading (litres). Readings must arrive in
  /// chronological order. A negative reading is ignored defensively —
  /// a corrupt decode must never derail the bracket.
  void observe(double fuelLevelL) {
    if (fuelLevelL < 0) return;

    switch (_phase) {
      case _Phase.beforeFill:
        final base = _baseLevelL;
        if (base != null && fuelLevelL > base + minStepL) {
          // A step-up — the pump operation has started.
          _phase = _Phase.filling;
          _startLevelL = base;
          _peakLevelL = fuelLevelL;
        } else {
          // Still pre-fill: track the level (it drifts down while
          // driving). Never let `_baseLevelL` rise here — a gentle
          // creep up without a clear step is treated as noise.
          if (base == null || fuelLevelL < base) {
            _baseLevelL = fuelLevelL;
          }
        }
      case _Phase.filling:
        if (fuelLevelL >= _peakLevelL) {
          _peakLevelL = fuelLevelL;
        } else if (fuelLevelL < _peakLevelL - settleToleranceL) {
          // The level has fallen clear of the peak — the fill is over
          // and the car is being driven away.
          _finalizeOrDiscard(nextBaseL: fuelLevelL);
        }
      case _Phase.complete:
        // First genuine fill wins — ignore everything after.
        break;
    }
  }

  /// The detected pump bracket, or null when no genuine fill has been
  /// observed yet.
  ///
  /// Returns a result in two cases:
  ///   * `complete` — the fill settled (a decline past the peak was
  ///     seen); the finalized bracket.
  ///   * `filling` with the net rise already past [riseThresholdL] —
  ///     a *provisional* bracket, so a user who saves the form the
  ///     instant they finish fuelling (before any decline) still gets
  ///     the real fill bracketed.
  PumpBracket? get bracket {
    if (_completed != null) return _completed;
    if (_phase == _Phase.filling &&
        _peakLevelL - _startLevelL >= riseThresholdL) {
      return PumpBracket(startL: _startLevelL, endL: _peakLevelL);
    }
    return null;
  }

  /// True once a genuine pump operation has been bracketed.
  bool get hasBracket => bracket != null;

  void _finalizeOrDiscard({required double nextBaseL}) {
    if (_peakLevelL - _startLevelL >= riseThresholdL) {
      _completed = PumpBracket(startL: _startLevelL, endL: _peakLevelL);
      _phase = _Phase.complete;
    } else {
      // The rise never reached the threshold — sensor noise, not a
      // fill. Reset and keep watching.
      _phase = _Phase.beforeFill;
      _baseLevelL = nextBaseL;
    }
  }
}

enum _Phase { beforeFill, filling, complete }

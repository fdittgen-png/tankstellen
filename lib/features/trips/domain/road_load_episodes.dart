// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

/// #4203 — the contextual episodes a road-load track derives. They explain
/// consumption without blaming the driver on their own: a stop is traffic,
/// a curve slowed into smoothly is good driving, and only the oscillation
/// pattern is a behaviour worth coaching.

/// A standstill between two moving stretches.
@immutable
class StopEpisode {
  const StopEpisode({required this.start, required this.duration});

  final DateTime start;
  final Duration duration;
}

/// How a curve was approached.
enum CurveApproach {
  /// Slowed early and gently, left without a burst — no waste.
  smooth,

  /// Hard braking right at the curve, then a strong re-acceleration out.
  lateBrakeHardExit,

  /// Not enough evidence around the curve to say.
  unknown,
}

/// A stretch of sustained, confidently measured turning.
@immutable
class CurveEpisode {
  const CurveEpisode({
    required this.start,
    required this.end,
    required this.entrySpeedMps,
    required this.minSpeedMps,
    required this.peakDecelMps2,
    required this.exitAccelMps2,
    required this.approach,
  });

  final DateTime start;
  final DateTime end;

  /// Highest speed in the approach window before the curve.
  final double entrySpeedMps;
  final double minSpeedMps;

  /// Strongest deceleration (positive m/s²) just before and inside it.
  final double peakDecelMps2;

  /// Strongest acceleration in the exit window after it.
  final double exitAccelMps2;
  final CurveApproach approach;
}

/// Accelerate → brake → accelerate without stopping: energy bought and
/// thrown away, counted as ONE contextual event.
@immutable
class OscillationEpisode {
  const OscillationEpisode({
    required this.start,
    required this.end,
    required this.peakAccelMps2,
    required this.peakDecelMps2,
  });

  final DateTime start;
  final DateTime end;
  final double peakAccelMps2;
  final double peakDecelMps2;
}

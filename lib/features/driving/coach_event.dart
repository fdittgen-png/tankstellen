import 'package:flutter/foundation.dart';

/// One real-time coach fire decision (#1273).
///
/// Emitted alongside the haptic vibration whenever the
/// [HapticEcoCoach] heuristic matches — sustained > 75 % throttle with
/// < 10 km/h Δspeed across the rolling 5 s window. Identical 30 s
/// cooldown is shared with the haptic surface; the visual SnackBar in
/// [TripRecordingScreen] is a downstream subscriber, not a parallel
/// firing path.
///
/// Carries cheap diagnostic context (averaged throttle + speed delta)
/// so a future debug overlay or analytics breadcrumb can record
/// *what* was happening when the coach fired without re-running the
/// heuristic. The fields are intentionally simple — anything that
/// would require a second pass over the window stays out.
@immutable
class CoachEvent {
  /// Wall-clock at which the heuristic fired. Sourced from the same
  /// clock seam the coach uses, so tests with an injected `clock`
  /// observe deterministic timestamps.
  final DateTime firedAt;

  /// Mean throttle across the window that triggered the fire — always
  /// above the heuristic's threshold (75 % by default). Surfaced for
  /// future tooltips / breadcrumbs; the SnackBar copy itself does not
  /// quote the number.
  final double avgThrottlePercent;

  /// Absolute speed change from the first to the last reading in the
  /// window. Always below the heuristic's `maxSpeedDeltaKmh` (10 km/h
  /// by default) — a fire only happens when the driver is *not*
  /// genuinely accelerating.
  final double speedDeltaKmh;

  const CoachEvent({
    required this.firedAt,
    required this.avgThrottlePercent,
    required this.speedDeltaKmh,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachEvent &&
          firedAt == other.firedAt &&
          avgThrottlePercent == other.avgThrottlePercent &&
          speedDeltaKmh == other.speedDeltaKmh;

  @override
  int get hashCode =>
      Object.hash(firedAt, avgThrottlePercent, speedDeltaKmh);

  @override
  String toString() => 'CoachEvent(firedAt: $firedAt, '
      'avgThrottle: ${avgThrottlePercent.toStringAsFixed(1)}%, '
      'speedDelta: ${speedDeltaKmh.toStringAsFixed(1)} km/h)';
}

import 'package:meta/meta.dart';

/// One composite "driving score" for a single trip on the Trip detail
/// Insights tab (#1041 phase 5a — Card A).
///
/// The score is a 0..100 integer where 100 is "no behaviour-driven
/// waste detected" and 0 is "every category capped out simultaneously".
/// Each public penalty field is the contribution (in score points)
/// subtracted from the starting 100 — exposed so the UI can surface
/// the top one or two penalty lines as a small explanatory chip row
/// without having to recompute anything.
///
/// The class is intentionally UI-agnostic — no `BuildContext`, no
/// `AppLocalizations`. The calculator in
/// `driving_score_calculator.dart` produces this from raw
/// [TripSample]s; the same value-object can be persisted, replayed, or
/// aggregated across trips later (phase 4 / phase 5) without touching
/// UI code.
@immutable
class DrivingScore {
  /// 0..100 composite. Higher is better. Always clamped to the
  /// inclusive [0, 100] range by the calculator.
  final int score;

  /// Score-points subtracted because of idle time (engine on, speed
  /// near zero). Capped at 25 by the calculator. Documented weights
  /// live alongside the calculator constants.
  final double idlingPenalty;

  /// Score-points subtracted because of hard-acceleration events
  /// (≥ 3.0 m/s²). Capped at 15.
  final double hardAccelPenalty;

  /// Score-points subtracted because of hard-braking events
  /// (≤ -3.0 m/s²). Capped at 15.
  final double hardBrakePenalty;

  /// Score-points subtracted because of time spent above the
  /// high-RPM threshold (3000 RPM). Capped at 20.
  final double highRpmPenalty;

  /// Score-points subtracted because of time at full throttle. Capped
  /// at 10. Persisted [TripSample]s do not currently carry throttle
  /// position, so this contribution stays at 0 for legacy trips — the
  /// value object still exposes the field so UI / future calculator
  /// versions don't need a schema change when throttle data lands.
  final double fullThrottlePenalty;

  const DrivingScore({
    required this.score,
    required this.idlingPenalty,
    required this.hardAccelPenalty,
    required this.hardBrakePenalty,
    required this.highRpmPenalty,
    required this.fullThrottlePenalty,
  });

  /// A "perfect" 100-point score with no penalties — used as a sentinel
  /// in tests and as the natural identity for empty trips (the
  /// calculator returns this for `samples.length < 2`).
  static const DrivingScore perfect = DrivingScore(
    score: 100,
    idlingPenalty: 0,
    hardAccelPenalty: 0,
    hardBrakePenalty: 0,
    highRpmPenalty: 0,
    fullThrottlePenalty: 0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivingScore &&
        other.score == score &&
        other.idlingPenalty == idlingPenalty &&
        other.hardAccelPenalty == hardAccelPenalty &&
        other.hardBrakePenalty == hardBrakePenalty &&
        other.highRpmPenalty == highRpmPenalty &&
        other.fullThrottlePenalty == fullThrottlePenalty;
  }

  @override
  int get hashCode => Object.hash(
        score,
        idlingPenalty,
        hardAccelPenalty,
        hardBrakePenalty,
        highRpmPenalty,
        fullThrottlePenalty,
      );

  @override
  String toString() => 'DrivingScore('
      'score: $score, '
      'idling: ${idlingPenalty.toStringAsFixed(1)}, '
      'hardAccel: ${hardAccelPenalty.toStringAsFixed(1)}, '
      'hardBrake: ${hardBrakePenalty.toStringAsFixed(1)}, '
      'highRpm: ${highRpmPenalty.toStringAsFixed(1)}, '
      'fullThrottle: ${fullThrottlePenalty.toStringAsFixed(1)})';
}

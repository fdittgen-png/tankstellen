import 'package:flutter/foundation.dart';

/// Predictive-maintenance signals derived from OBD2 trip-trend analysis
/// (#1124).
///
/// Two pilot heuristics ship with this entity:
///
/// * [idleRpmCreep] — a sustained upward drift of the median idle RPM
///   over the last 30 days. The classic early sign of a slowly clogging
///   air filter or a drifting idle-air-control valve. Cheap to detect
///   from the speed + RPM samples we already persist on every trip.
/// * [mafDeviation] — a sustained drop in fuel rate at steady-cruise
///   operating points (throttle proxy via vehicle on-cruise: speed
///   60–100 km/h, RPM 1500–2500). Lower-than-expected fuel rate at the
///   same cruise envelope is a proxy for restricted intake mass-flow,
///   the canonical "MAF deviation" symptom. We use fuel rate as a
///   proxy because raw MAF readings are not currently persisted in the
///   trip history; the rate-based signal still surfaces the same
///   maintenance class without changing the on-disk format.
///
/// Both heuristics need at least six trips (three per half of the
/// 30-day window) before they emit anything — fewer trips than that
/// and the comparison is noise. See `maintenance_analyzer.dart` for
/// the math.
enum MaintenanceSignal {
  idleRpmCreep,
  mafDeviation,
}

/// One predictive-maintenance suggestion surfaced to the user (#1124).
///
/// Plain Dart class with `final` fields and a const constructor —
/// matches the style of [TripSummary] / [TripSample] in
/// `lib/features/consumption/domain/trip_recorder.dart` (the trip
/// entities those are paired with). No freezed because we don't need
/// `copyWith` / unions / equality beyond identity here, and adding a
/// new generated `.freezed.dart` for a 5-field value type is over-
/// engineering for what amounts to a small UI payload.
@immutable
class MaintenanceSuggestion {
  /// Which heuristic produced this suggestion. Drives the UI's
  /// localised title / body lookup — the analyzer never produces a
  /// string itself, so the presentation layer can render the same
  /// signal in any of the supported locales.
  final MaintenanceSignal signal;

  /// Confidence in `[0.0, 1.0]`. Computed as
  /// `min(1.0, sampleTripCount / 20)` — a saturating ramp that hits
  /// 100 % once we have 20 trips of usable data. The UI renders this
  /// as a percentage; the snooze-30-days flow respects it but does
  /// not vary by it (the user always owns the dismiss decision).
  final double confidence;

  /// Observed delta in percent. Positive for [idleRpmCreep] (idle
  /// RPM rose by this much), and reported as a positive magnitude for
  /// [mafDeviation] (fuel rate dropped by this much) so the UI
  /// always renders a non-negative number alongside the signal copy.
  final double observedDelta;

  /// Number of trips the analyzer considered for this signal across
  /// both halves of the 30-day window. Drives both the confidence
  /// ramp and the user-facing "n trips analysed" copy.
  final int sampleTripCount;

  /// When this suggestion was computed. Persisted alongside the
  /// signal so a refresh that comes back identical doesn't reset the
  /// "fresh" badge — the UI compares this against the last-shown
  /// stamp to decide whether to highlight the card.
  final DateTime computedAt;

  const MaintenanceSuggestion({
    required this.signal,
    required this.confidence,
    required this.observedDelta,
    required this.sampleTripCount,
    required this.computedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceSuggestion &&
          other.signal == signal &&
          other.confidence == confidence &&
          other.observedDelta == observedDelta &&
          other.sampleTripCount == sampleTripCount &&
          other.computedAt == computedAt);

  @override
  int get hashCode => Object.hash(
        signal,
        confidence,
        observedDelta,
        sampleTripCount,
        computedAt,
      );
}

// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../../../domain/trip_recorder.dart';
import '../lesson_format.dart';

/// Lesson id for the high-speed-band penalty. Stable, non-localized.
const String highSpeedBandLessonId = 'highSpeedBand';

/// Speed (km/h) at and above which aerodynamic drag starts to dominate
/// consumption — drag rises with the square of speed, so the L/100km
/// penalty between 110 and 130 km/h is steep (#2287).
const double kHighSpeedThresholdKmh = 110.0;

/// Minimum share of the trip spent in the high-speed band before the
/// lesson fires — short overtakes shouldn't trigger coaching.
const double kHighSpeedMinShare = 0.10;

/// High-speed-band consumption-penalty lesson (#2287).
///
/// Computed purely from the sample stream's road speed, so it fires for
/// **both** OBD2 and GPS-only trips (GPS supplies speed). Credits each
/// inter-sample interval to "high speed" when the interval's start sample
/// is at or above [kHighSpeedThresholdKmh], then fires when that share
/// clears [kHighSpeedMinShare].
///
/// Where litres are derivable (the summary carries
/// [TripSummary.fuelLitersConsumed]) the estimated extra litres is the
/// high-speed time-share × total litres × a drag-penalty factor —
/// honest and unit-testable. On a GPS-only / no-fuel-rate trip litres are
/// absent, so the lesson still fires (impact = the time-share) and simply
/// omits the litres badge — graceful degradation.
class HighSpeedBandRule implements DrivingLessonRule {
  const HighSpeedBandRule();

  /// Fraction of the high-speed litres considered *wasted* vs. driving
  /// the same distance at an efficient cruise — a conservative 20 %.
  static const double _dragPenaltyFactor = 0.20;

  @override
  String get id => highSpeedBandLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final share = highSpeedTimeShare(
      context.samples,
      thresholdKmh: kHighSpeedThresholdKmh,
    );
    if (share < kHighSpeedMinShare) return null;

    final pct = formatLessonPercent(share * 100.0);
    final totalLiters = context.summary.fuelLitersConsumed;
    // Estimated extra litres burned by the drag penalty in the high-speed
    // band. Null when the trip has no fuel figure (GPS-only) — the lesson
    // then ranks on the time-share alone and shows no litres badge.
    final wastedLiters = (totalLiters != null && totalLiters > 0)
        ? totalLiters * share * _dragPenaltyFactor
        : null;

    return DrivingLesson(
      id: id,
      // Litres dominate the waste ranking when known; otherwise the
      // time-share keeps the lesson in the list at a modest weight.
      impact: wastedLiters ?? share,
      metricValue: wastedLiters ?? share,
      title: wastedLiters != null
          ? l.insightHighSpeedBand(pct, formatLessonLiters(wastedLiters))
          : l.insightHighSpeedBandNoFuel(pct),
      advice: l.lessonAdviceHighSpeedBand,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: wastedLiters != null
          ? l.insightTrailingLitersWasted(formatLessonLiters(wastedLiters))
          : null,
    );
  }
}

/// Pure helper: the fraction (0..1) of trip *time* spent at or above
/// [thresholdKmh], crediting each inter-sample interval to whichever band
/// its START sample falls into (matching the throttle/RPM histogram +
/// analyzer accounting). Returns 0 for < 2 samples or a zero-duration
/// trip. Exposed for direct unit testing of the boundary behaviour.
double highSpeedTimeShare(
  List<TripSample> samples, {
  double thresholdKmh = kHighSpeedThresholdKmh,
}) {
  if (samples.length < 2) return 0.0;
  final ordered = List<TripSample>.of(samples)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  var highSeconds = 0.0;
  var totalSeconds = 0.0;
  for (var i = 0; i < ordered.length - 1; i++) {
    final start = ordered[i];
    final next = ordered[i + 1];
    final dt = next.timestamp.difference(start.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;
    totalSeconds += dt;
    if (start.speedKmh >= thresholdKmh) highSeconds += dt;
  }
  if (totalSeconds <= 0) return 0.0;
  return highSeconds / totalSeconds;
}

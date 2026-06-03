// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../../../domain/services/obd2_analytics_signals.dart';
import '../../../domain/trip_recorder.dart';

/// Lesson id for the smooth-driving praise. Stable, non-localized.
const String smoothDrivingLessonId = 'smoothDriving';

/// Minimum trip distance (km) before the praise is meaningful — a 200 m
/// crawl out of a car park shouldn't earn a "smooth driving" badge.
const double kSmoothDrivingMinDistanceKm = 2.0;

/// Speed (km/h) above which a sample counts as the car actually driving
/// — distinguishes a genuine cruise from a stationary engine-on dwell so
/// a pure-idle trip never earns praise.
const double kSmoothDrivingMovingSpeedKmh = 5.0;

/// Smooth-driving praise lesson (#2287) — the one positive-reinforcement
/// rule in the registry.
///
/// Fires when a real, *driven* trip ([kSmoothDrivingMinDistanceKm]+ km,
/// enough samples to judge, at least some genuine movement) had **zero**
/// harsh acceleration / deceleration events, derived from the #2286
/// [Obd2AnalyticsSignals] harsh classification over the sample stream.
/// Because the classification keys only off road speed, the rule works
/// for OBD2 and GPS-only trips alike — graceful degradation when no
/// engine PIDs are present.
///
/// The "actually moved" gate stops a pure-idle / stop-and-go dwell (which
/// has its own idling lesson) from being praised as smooth.
///
/// Impact is intentionally a small fixed weight: praise should appear in
/// the lesson list but never outrank an actual waste lesson, so a trip
/// that was *mostly* smooth but had one expensive idle still leads with
/// the idle.
class SmoothDrivingRule implements DrivingLessonRule {
  const SmoothDrivingRule();

  /// Fixed low ranking weight — praise sorts below any real waste lesson
  /// but above nothing.
  static const double _praiseImpact = 0.001;

  @override
  String get id => smoothDrivingLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final samples = context.samples;
    if (context.summary.distanceKm < kSmoothDrivingMinDistanceKm) return null;
    if (samples.length < 3) return null;
    // The car must actually have driven — a pure-idle trip is not smooth.
    final moved = samples.any((s) => s.speedKmh > kSmoothDrivingMovingSpeedKmh);
    if (!moved) return null;

    final harshEvents = countHarshEvents(samples);
    if (harshEvents > 0) return null;

    return DrivingLesson(
      id: id,
      impact: _praiseImpact,
      metricValue: 0,
      title: l.lessonSmoothDrivingTitle,
      advice: l.lessonAdviceSmoothDriving,
      // #2791 — praise, not waste: render green, not the error-red (i) icon.
      polarity: LessonPolarity.positive,
    );
  }
}

/// Pure helper: count of harsh acceleration + deceleration events across
/// [samples], using the #2286 per-sample derivation. Exposed for direct
/// unit testing. Sorts defensively (sample order is not guaranteed).
int countHarshEvents(List<TripSample> samples) {
  if (samples.length < 2) return 0;
  final ordered = List<TripSample>.of(samples)
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  var count = 0;
  for (var i = 1; i < ordered.length; i++) {
    final s = Obd2AnalyticsSignals.derive(
      ordered[i],
      previous: ordered[i - 1],
    );
    if (s.harshAcceleration || s.harshDeceleration) count++;
  }
  return count;
}

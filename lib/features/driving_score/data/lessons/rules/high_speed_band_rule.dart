// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../../../../trips/api.dart';
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
/// #4221 — the lesson states the high-speed time share only. It used to
/// quote "wasted" litres as trip litres × share × a fixed 20 % drag factor:
/// a model presented as a measurement, so no litre figure is shown.
class HighSpeedBandRule implements DrivingLessonRule {
  const HighSpeedBandRule();

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
    return DrivingLesson(
      id: id,
      impact: share * 100.0,
      metricValue: share,
      title: l.insightHighSpeedBandNoFuel(pct),
      advice: l.lessonAdviceHighSpeedBand,
      subtitle: l.insightSubtitlePctOfTrip(pct),
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

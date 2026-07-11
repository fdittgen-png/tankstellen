// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the hard-acceleration cost line. Stable, non-localized.
const String hardAccelLessonId = 'hardAccel';

/// Hard-acceleration lesson (#2251 — migrated from the
/// `insightHardAccel` cost line).
///
/// Fires when the analyzer counted hard-acceleration events whose
/// estimated waste cleared the noise floor. The legacy card built its
/// headline from the event count in the insight metadata (`eventCount`),
/// not a percent — this rule reproduces that exactly. Impact / metric is
/// the litres wasted so ranking matches the old card.
///
/// #2789 C5 — single source of truth. When the phone IMU actually RAN for
/// this trip (`summary.imuActive`, #2895), the headline event count is
/// sourced from the IMU-preferred figure the recording pipeline persisted
/// into [TripSummary.harshAccelerations] — the same accurate inertial count
/// the driving score and [HardBrakeRule] read — instead of the noisy GPS
/// speed-derivative `eventCount` in the analyzer metadata (which can
/// over-count Doppler noise into impossible spikes, the #2895 16-vs-0 bug).
/// When no IMU ran, the (now physically-clamped, #2895) GPS-derived count
/// remains the source. The estimated litres wasted (impact / ranking /
/// trailing) still come from the analyzer's cost line so the cost model is
/// unchanged.
class HardAccelRule implements DrivingLessonRule {
  const HardAccelRule();

  @override
  String get id => hardAccelLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightHardAccel');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final pct = formatLessonPercent(insight.percentOfTrip);
    // #2789 C5 — prefer the IMU-resolved count when the inertial sensor ran;
    // otherwise fall back to the GPS-derived event count from the analyzer
    // metadata bag (the legacy source).
    final summary = context.summary;
    final eventCount = summary.imuActive
        ? summary.harshAccelerations
        : (insight.metadata['eventCount'] ?? 0).toInt();
    // #3557 — zero events refutes the lesson's premise: when the trusted
    // (IMU-preferred) count is 0, the analyzer's litres are GPS
    // speed-derivative noise and the card would read the absurd
    // "0 hard accelerations: 2.3 L wasted". Mirror of [HardBrakeRule]'s
    // guard, which #2789 kept there but dropped here.
    if (eventCount <= 0) return null;
    final count = eventCount.toString();
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightHardAccel(count, liters),
      advice: l.lessonAdviceHardAccel,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

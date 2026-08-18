// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the full-throttle cost line (#2461). Stable, non-localized.
const String fullThrottleLessonId = 'fullThrottle';

/// Full-throttle coaching lesson (#2461 — surfaces the
/// `insightFullThrottle` cost line).
///
/// Fires when the analyzer counted time at full throttle (pedal else
/// throttle ≥ 90 %) whose estimated waste — easing onto the pedal would
/// have burned ~70 % of the fuel — cleared the noise floor. Impact /
/// metric is the litres wasted so it ranks alongside the other cost lines.
class FullThrottleRule implements DrivingLessonRule {
  const FullThrottleRule();

  @override
  String get id => fullThrottleLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightFullThrottle');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final pct = formatLessonPercent(insight.percentOfTrip);
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightFullThrottle(pct, liters),
      advice: l.lessonAdviceFullThrottle,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

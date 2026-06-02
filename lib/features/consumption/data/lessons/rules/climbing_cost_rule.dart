// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the climbing-fuel cost line (#2693 C6). Stable.
const String climbingCostLessonId = 'climbingCost';

/// Climbing-fuel coaching lesson (#2693 C6 — surfaces the
/// `insightClimbingCost` cost line).
///
/// Fires when the analyzer's confident-grade pass attributed enough extra
/// fuel to a sustained climb to clear the noise floor. The headline carries
/// the peak confident grade (from the insight metadata) so the driver can
/// place the cost on the steepest part of the trip.
class ClimbingCostRule implements DrivingLessonRule {
  const ClimbingCostRule();

  @override
  String get id => climbingCostLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightClimbingCost');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final pct = formatLessonPercent(insight.percentOfTrip);
    final gradePct =
        formatLessonPercent((insight.metadata['gradePercent'] ?? 0).toDouble());
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightClimbingCost(gradePct, pct, liters),
      advice: l.lessonAdviceClimbingCost,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

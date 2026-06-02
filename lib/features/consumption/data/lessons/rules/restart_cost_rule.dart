// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the stop-and-go restart cost line (#2694 C8). Stable.
const String restartCostLessonId = 'restartCost';

/// Stop-and-go restart coaching lesson (#2694 C8 — surfaces the
/// `insightRestartCost` cost line).
///
/// Fires when the analyzer counted enough genuine stop→accelerate restarts
/// that their estimated extra fuel cleared the noise floor. The headline
/// carries the restart count (from the insight metadata); the category is
/// count-based, so there is no time/distance percentage to show.
class RestartCostRule implements DrivingLessonRule {
  const RestartCostRule();

  @override
  String get id => restartCostLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightRestartCost');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final count = (insight.metadata['restartCount'] ?? 0).toInt().toString();
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightRestartCost(count, liters),
      advice: l.lessonAdviceRestartCost,
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the high-RPM cost line. Stable, non-localized.
const String highRpmLessonId = 'highRpm';

/// High-RPM lesson (#2251 — migrated from the `insightHighRpm` cost
/// line).
///
/// Fires when the analyzer surfaced a high-RPM cost line (time above the
/// 3000-RPM threshold burned measurably more fuel than the moderate-RPM
/// counterfactual). Title is the legacy `insightHighRpm` copy; impact /
/// metric is the litres wasted. Advice nudges toward earlier upshifts.
class HighRpmRule implements DrivingLessonRule {
  const HighRpmRule();

  @override
  String get id => highRpmLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightHighRpm');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final pct = formatLessonPercent(insight.percentOfTrip);
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightHighRpm(pct, liters),
      advice: l.lessonAdviceHighRpm,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

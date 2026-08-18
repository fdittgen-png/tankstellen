// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the idling cost line — also the GPX extension
/// attribute and the insight tile key. Stable, non-localized.
const String idlingLessonId = 'idling';

/// Idling lesson (#2251 — migrated from the `insightIdling` cost line).
///
/// Fires when the analyzer surfaced an idling cost line for the trip
/// (engine on, car stationary, > the noise floor of wasted fuel). The
/// title is the legacy `insightIdling` copy verbatim; the impact is the
/// litres wasted so the registry ranks it among the other cost lines
/// exactly as the old card did. Advice points the driver at the
/// engine-off remedy.
class IdlingRule implements DrivingLessonRule {
  const IdlingRule();

  @override
  String get id => idlingLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightIdling');
    if (insight == null) return null;

    final liters = formatLessonLiters(insight.litersWasted);
    final pct = formatLessonPercent(insight.percentOfTrip);
    return DrivingLesson(
      id: id,
      impact: insight.litersWasted,
      metricValue: insight.litersWasted,
      title: l.insightIdling(pct, liters),
      advice: l.lessonAdviceIdling,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(liters),
    );
  }
}

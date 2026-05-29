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
    // The card pulled the event count out of the analyzer metadata bag.
    final count = (insight.metadata['eventCount'] ?? 0).toInt().toString();
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
